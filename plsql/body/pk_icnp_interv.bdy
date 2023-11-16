/*-- Last Change Revision: $Rev: 2027230 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp_interv IS

    --------------------------------------------------------------------------------
    -- GLOBAL VARIABLES
    --------------------------------------------------------------------------------

    -- Identifes the owner in the log mechanism
    g_package_owner pk_icnp_type.t_package_owner;

    -- Identifes the package in the log mechanism
    g_package_name pk_icnp_type.t_package_name;

    --------------------------------------------------------------------------------
    -- PRIVATE METHODS [DEBUG]
    --------------------------------------------------------------------------------

    /*
     * Wrapper of the method from the alertlog mechanism that creates a debug log 
     * message.
     *
     * @param i_text Text to log.
     * @param i_func_name Function / procedure name.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 25/Jul/2011
    */
    PROCEDURE log_debug
    (
        i_text      VARCHAR2,
        i_func_name VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_debug(text => i_text, object_name => g_package_name, sub_object_name => i_func_name);
    END log_debug;

    --------------------------------------------------------------------------------
    -- METHODS [INIT]
    --------------------------------------------------------------------------------

    /**
     * Executes all the instructions needed to correctly initialize the package.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE initialize IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'initialize';
    
    BEGIN
        -- Initializes the log mechanism
        g_package_owner := 'ALERT';
        g_package_name  := pk_alertlog.who_am_i;
        pk_alertlog.log_init(g_package_name);
    
        -- Log message
        log_debug(c_func_name || '()', c_func_name);
    END;

    --------------------------------------------------------------------------------
    -- METHODS [UTILS]
    --------------------------------------------------------------------------------

    /**
     * Gets the index of the first element in the collection that has the given
     * composition identifier.
     * 
     * @param i_composition_id Identifier of the composition (an intervention).
     * @param i_interv_row_coll Collection of icnp_epis_intervention rows that will be
     *                          fetched.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 25/Jul/2011 (v2.6.1)
    */
    FUNCTION get_elem_index_by_compo
    (
        i_composition_id  IN icnp_epis_intervention.id_composition%TYPE,
        i_interv_row_coll IN ts_icnp_epis_intervention.icnp_epis_intervention_tc
    ) RETURN PLS_INTEGER IS
        l_index PLS_INTEGER := -1;
    
    BEGIN
        -- Loop through all the elements in the collection trying to find the 
        -- intervention given
        FOR i IN 1 .. i_interv_row_coll.count
        LOOP
            IF i_composition_id = i_interv_row_coll(i).id_composition
            THEN
                l_index := i;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_index;
    
    END get_elem_index_by_compo;

    --------------------------------------------------------------------------------
    -- METHODS [GET INTERV ROW]
    --------------------------------------------------------------------------------

    /**
     * Gets the intervention data (icnp_epis_intervention row) of all the intervention
     * identifiers given as input parameter.
     *
     * @param i_interv_ids Collection with the intervention identifiers.
     * 
     * @return Collection with the intervention data (icnp_epis_intervention row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION get_interv_rows(i_interv_ids IN table_number) RETURN ts_icnp_epis_intervention.icnp_epis_intervention_tc IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_interv_rows';
        l_interv_row_coll ts_icnp_epis_intervention.icnp_epis_intervention_tc;
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT iei.*
          BULK COLLECT
          INTO l_interv_row_coll
          FROM icnp_epis_intervention iei
         WHERE iei.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            t.column_value id_icnp_epis_interv
                                             FROM TABLE(i_interv_ids) t);
    
        RETURN l_interv_row_coll;
    
    END get_interv_rows;

    /**
     * Gets the intervention data (icnp_epis_intervention row) of a given intervention
     * identifier given as input parameter.
     *
     * @param i_epis_interv_id The intervention identifier.
     * 
     * @return The intervention data (icnp_epis_intervention row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION get_interv_row(i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE)
        RETURN icnp_epis_intervention%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_interv_row';
        l_interv_row icnp_epis_intervention%ROWTYPE;
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT iei.*
          INTO l_interv_row
          FROM icnp_epis_intervention iei
         WHERE iei.id_icnp_epis_interv = i_epis_interv_id;
    
        RETURN l_interv_row;
    
    END get_interv_row;

    --------------------------------------------------------------------------------
    -- METHODS [GETS]
    --------------------------------------------------------------------------------

    /**
     * Checks if at least one planned execution of a given intervention was executed.
     *
     * @param i_epis_interv_id The intervention identifier.
     *
     * @return True if at least one planned execution was executed, false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION get_interv_has_execs(i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE) RETURN BOOLEAN IS
        l_count     PLS_INTEGER := 0;
        l_has_execs BOOLEAN;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM icnp_interv_plan iip
         WHERE iip.id_icnp_epis_interv = i_epis_interv_id
           AND iip.flg_status = pk_icnp_constant.g_interv_plan_status_executed;
    
        l_has_execs := l_count > 0;
        RETURN l_has_execs;
    
    END get_interv_has_execs;

    /**
     * Counts the number of planned executions associated with a given intervention.
     * Are considered planned executions all of them that were not executed or 
     * cancelled.
     *
     * @param i_epis_interv_id The intervention identifier.
     *
     * @return The number of planned executions.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 17/Ago/2011 (v2.6.1)
    */
    FUNCTION get_interv_planned_execs_count(i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE)
        RETURN PLS_INTEGER IS
        l_count PLS_INTEGER := 0;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM icnp_interv_plan iip
         WHERE iip.id_icnp_epis_interv = i_epis_interv_id
           AND iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_pending,
                                  pk_icnp_constant.g_interv_plan_status_requested,
                                  pk_icnp_constant.g_interv_plan_status_suspended);
        RETURN l_count;
    
    END get_interv_planned_execs_count;

    /**
     * Checks if a given intervention has planned executions. Are considered planned
     * executions all of them that were not executed or cancelled.
     *
     * @param i_epis_interv_id The intervention identifier.
     *
     * @return True if at least one planned execution was executed, false otherwise.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION get_interv_has_planned_execs(i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE)
        RETURN BOOLEAN IS
    
        l_count             PLS_INTEGER;
        l_has_planned_execs BOOLEAN;
    
    BEGIN
    
        l_count             := get_interv_planned_execs_count(i_epis_interv_id => i_epis_interv_id);
        l_has_planned_execs := l_count > 0;
        RETURN l_has_planned_execs;
    
    END get_interv_has_planned_execs;

    /**
     * Checks if a given intervention is associated and active for a certain patient.
     *
     * @param i_patient The patient identifier.
     * @param i_interv_compo The intervention identifier. 
     * 
     * @return Identifier of the icnp_epis_intervention that is already active for the given patient.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 06/Jun/2011
    */
    FUNCTION get_interv_existent_id
    (
        i_patient      IN patient.id_patient%TYPE,
        i_interv_compo IN icnp_epis_intervention.id_composition%TYPE,
        i_episode      IN episode.id_episode%TYPE
        
    ) RETURN icnp_epis_intervention.id_icnp_epis_interv%TYPE IS
        -- Identifier of the icnp_epis_intervention that is already active for the given patient
        l_epis_interv_id icnp_epis_intervention.id_icnp_epis_interv%TYPE;
    
        -- Cursor that returns all the registered active interventions
        CURSOR c_interv_exists IS
            SELECT iei.id_icnp_epis_interv
              FROM icnp_epis_intervention iei
             WHERE iei.id_patient = i_patient
               AND iei.id_composition = i_interv_compo
               AND iei.id_episode = i_episode
               AND iei.id_episode_destination IS NULL
               AND iei.flg_status IN (pk_icnp_constant.g_epis_interv_status_ongoing,
                                      pk_icnp_constant.g_epis_interv_status_requested,
                                      pk_icnp_constant.g_epis_interv_status_suspended);
    BEGIN
        OPEN c_interv_exists;
        FETCH c_interv_exists
            INTO l_epis_interv_id;
        CLOSE c_interv_exists;
    
        RETURN l_epis_interv_id;
    
    END get_interv_existent_id;

    /**
     * Gets the execution data (icnp_interv_plan row) of the next intervention 
     * planned execution.
     * 
     * @param i_epis_interv_id The intervention identifier.
     *
     * @return The execution data (icnp_interv_plan row) of the next intervention.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION get_interv_next_exec_row(i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE)
        RETURN icnp_interv_plan%ROWTYPE IS
    
        -- Variables
        l_exec_row icnp_interv_plan%ROWTYPE;
        -- Cursors
        CURSOR c_interv_next_exec IS
            SELECT iip.*
              FROM icnp_interv_plan iip
             WHERE iip.id_icnp_epis_interv = i_epis_interv_id
               AND iip.flg_status IN
                   (pk_icnp_constant.g_interv_plan_status_pending, pk_icnp_constant.g_interv_plan_status_requested)
             ORDER BY iip.dt_plan_tstz;
    
    BEGIN
        OPEN c_interv_next_exec;
        FETCH c_interv_next_exec
            INTO l_exec_row;
        CLOSE c_interv_next_exec;
    
        RETURN l_exec_row;
    
    END get_interv_next_exec_row;

    /**
     * Gets the date of the next execution when a new intervention record is first 
     * created or later when it's edited. Usually we use the actual date, but when
     * the frequency is "no schedule" we really don't have a next execution planned.
     * On those cases, the user can execute an intervention "on demand", when he 
     * wants.
     * 
     * @param i_flg_type The type of frequency (once, no schedule or with recurrence).
     * @param i_dt_begin_tstz Date that indicates when the task should be performed.
     * 
     * @return The date of the next planned execution.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 27/Jul/2011 (v2.6.1)
    */
    FUNCTION get_interv_dt_next_for_new_rec
    (
        i_flg_type      IN icnp_epis_intervention.flg_type%TYPE,
        i_dt_begin_tstz IN icnp_epis_intervention.dt_begin_tstz%TYPE
    ) RETURN icnp_epis_intervention.dt_next_tstz%TYPE IS
        l_dt_next_tstz icnp_epis_intervention.dt_next_tstz%TYPE;
    
    BEGIN
    
        IF i_flg_type IN (pk_icnp_constant.g_epis_interv_type_once, pk_icnp_constant.g_epis_interv_type_recurrence)
        THEN
            l_dt_next_tstz := i_dt_begin_tstz;
        ELSIF i_flg_type = pk_icnp_constant.g_epis_interv_type_no_schedule
        THEN
            l_dt_next_tstz := NULL;
        ELSE
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_unexpected_error,
                                            text_in       => 'Unable to determine the date of the next execution when the type is ' ||
                                                             i_flg_type);
        END IF;
    
        RETURN l_dt_next_tstz;
    
    END get_interv_dt_next_for_new_rec;

    /**
     * Gets the new intervention status. The status must be updated whenever an action is 
     * performed by the user. Each tansition has an identifier that is also used in the 
     * state diagram.
     * 
     * @param i_epis_interv_id The intervention identifier whose status we want to update.
     * @param i_interv_type The type of the intervention (once, no schedule or with recurrence).
     * @param i_interv_status The status of the intervention.
     * @param i_action An action performed by the user that caused the status change.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 13/Jun/2011 (v2.6.1)
    */
    FUNCTION get_interv_status
    (
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_interv_type    IN icnp_epis_intervention.flg_type%TYPE,
        i_interv_status  IN icnp_epis_intervention.flg_status%TYPE,
        i_action         IN action.code_action%TYPE,
        i_force_status   IN VARCHAR2 DEFAULT 'N'
    ) RETURN icnp_epis_intervention.flg_status%TYPE IS
        c_func_name      CONSTANT pk_icnp_type.t_function_name := 'get_interv_status';
        c_invalid_status CONSTANT icnp_epis_intervention.flg_status%TYPE := '-';
        l_new_status        icnp_epis_intervention.flg_status%TYPE := c_invalid_status;
        l_has_execs         BOOLEAN;
        l_has_planned_execs BOOLEAN;
    
        /**
         * Calculates the status of the intervention when a cancel request action is 
         * performed. This algorithm is the same for all the intervention types.
        */
        PROCEDURE calc_st_for_cancel_req IS
        BEGIN
            IF i_interv_status = pk_icnp_constant.g_epis_interv_status_requested
               OR i_interv_status = pk_icnp_constant.g_epis_interv_status_cancelled -- Transition A6
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_cancelled;
            ELSIF i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing -- Transition E5
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_discont;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_suspended AND l_has_execs) -- Transition I3
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_discont;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_suspended AND NOT l_has_execs) -- Transition I1
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_cancelled;
            END IF;
        END;
    
        /**
         * Calculates the status of the intervention when an intervention is executed and
         * the type intervention of the intervention is "once" or "with recurrence".
        */
        PROCEDURE calc_st_for_exec_recurr IS
        BEGIN
            IF (i_interv_status = pk_icnp_constant.g_epis_interv_status_requested AND l_has_execs AND
               l_has_planned_execs) -- Transition A9
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_ongoing;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_requested AND l_has_execs AND
                  NOT l_has_planned_execs) -- Transition A5
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_executed;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing AND l_has_execs AND
                  NOT l_has_planned_execs) -- Transition E3
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_executed;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing AND l_has_execs AND
                  l_has_planned_execs) -- Transition E9
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the intervention when an intervention is executed and
         * the type intervention of the intervention is "no schedule".
        */
        PROCEDURE calc_st_for_exec_no_sched IS
        BEGIN
            IF (i_interv_status = pk_icnp_constant.g_epis_interv_status_requested AND l_has_execs) -- Transition A9
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_ongoing;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing AND l_has_execs) -- Transition E9
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the intervention when the pause action is performed.
         * This algorithm is the same for all the intervention types.
        */
        PROCEDURE calc_st_for_pause IS
        BEGIN
            IF i_interv_status = pk_icnp_constant.g_epis_interv_status_requested -- Transition A8
               OR (i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing AND
               i_force_status = pk_alert_constant.g_no) -- Transition E6
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_suspended;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing AND
                  i_force_status = pk_alert_constant.g_yes)
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_discont;
            ELSIF i_interv_status = pk_icnp_constant.g_epis_interv_status_suspended
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_discont;
            END IF;
        END;
    
        /**
         * Calculates the status of the intervention when the resume action is performed.
         * This algorithm is the same for all the intervention types.
        */
        PROCEDURE calc_st_for_resume IS
        BEGIN
            IF (i_interv_status = pk_icnp_constant.g_epis_interv_status_suspended AND NOT l_has_execs) -- Transition I3
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_requested;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_suspended AND l_has_execs) -- Transition I2
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_ongoing;
            END IF;
        END;
    
        /**
         * Calculates the status of the intervention when the resolve action is performed.
         * This algorithm is the same for all the intervention types.
        */
        PROCEDURE calc_st_for_resolve IS
        BEGIN
            IF i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing -- Transition E4
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_executed;
            ELSIF i_interv_status = pk_icnp_constant.g_epis_interv_status_requested -- Transition A4
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_cancelled;
            ELSIF i_interv_status = pk_icnp_constant.g_epis_interv_status_suspended -- Transition I3
            THEN
                l_new_status := 'N';
                -- l_new_status := pk_icnp_constant.g_epis_interv_status_cancelled;
            END IF;
        END;
    
        /**
         * Calculates the status of the intervention when the cancel execution action is 
         * performed. This algorithm is only executed for the interventions of type "once" 
         * or "with recurrence".
        */
        PROCEDURE calc_st_for_cancel_exec_recurr IS
        BEGIN
            IF (i_interv_status = pk_icnp_constant.g_epis_interv_status_requested AND l_has_planned_execs AND
               NOT l_has_execs) -- Transition A1
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_requested;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_requested AND NOT l_has_planned_execs AND
                  NOT l_has_execs) -- Transition A7
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_cancelled;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing AND l_has_planned_execs AND
                  l_has_execs) -- Transition E1
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_ongoing;
            ELSIF (i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing AND NOT l_has_planned_execs) -- Transition E2
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_executed;
            END IF;
        END;
    
        /**
         * Calculates the status of the intervention when the edit action is performed.
         * This algorithm is the same for all the intervention types.
        */
        PROCEDURE calc_st_for_edit IS
        BEGIN
            IF (i_interv_status = pk_icnp_constant.g_epis_interv_status_requested OR
               i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing) -- Transition A3, E7
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_requested;
            END IF;
        END;
    
        /**
         * Calculates the status of the intervention when the discontinued action is performed.
         * This algorithm is the same for all the intervention types.
        */
        PROCEDURE calc_st_for_discont IS
        BEGIN
            IF i_interv_status = pk_icnp_constant.g_epis_interv_status_ongoing -- Transition E10
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_discont;
            ELSIF i_interv_status = pk_icnp_constant.g_epis_interv_status_suspended
            THEN
                l_new_status := pk_icnp_constant.g_epis_interv_status_cancelled;
            END IF;
        END;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Gets the execution information for the given intervention
        l_has_execs         := get_interv_has_execs(i_epis_interv_id);
        l_has_planned_execs := get_interv_has_planned_execs(i_epis_interv_id);
    
        /*
         * Calculate the new intervention status.
         * First the action is evaluated, then the current intervention status.
        */
        IF i_action = pk_icnp_constant.g_action_interv_cancel
        THEN
            -- g_action_interv_cancel
            -- The algorithm is the same for all the intervention types 
            calc_st_for_cancel_req();
        
        ELSIF i_action = pk_icnp_constant.g_action_interv_exec
        THEN
            -- g_action_interv_exec
            -- The algorithm for the interventions of type "no schedule" doesn't have the 
            -- transitions E5 and E3
            IF i_interv_type = pk_icnp_constant.g_epis_interv_type_once
               OR i_interv_type = pk_icnp_constant.g_epis_interv_type_recurrence
            THEN
                calc_st_for_exec_recurr();
            ELSIF i_interv_type = pk_icnp_constant.g_epis_interv_type_no_schedule
            THEN
                calc_st_for_exec_no_sched();
                --calc_st_for_exec_recurr();
            END IF;
        
        ELSIF i_action = pk_icnp_constant.g_action_interv_pause
        THEN
            -- g_action_interv_pause
            -- The algorithm is the same for all the intervention types 
            calc_st_for_pause();
        
        ELSIF i_action = pk_icnp_constant.g_action_interv_resume
        THEN
            -- g_action_interv_resume
            -- The algorithm is the same for all the intervention types 
            calc_st_for_resume();
        
        ELSIF i_action = pk_icnp_constant.g_action_interv_resolve
        THEN
            -- g_action_interv_resolve
            -- The algorithm is the same for all the intervention types 
            calc_st_for_resolve();
        
        ELSIF i_action = pk_icnp_constant.g_action_interv_canc_exec
        THEN
            -- g_action_interv_canc_exec
            -- The interventions of type "no schedule" doesn't have the action cancel execution
            IF i_interv_type = pk_icnp_constant.g_epis_interv_type_once
               OR i_interv_type = pk_icnp_constant.g_epis_interv_type_recurrence
            THEN
                calc_st_for_cancel_exec_recurr();
            END IF;
        
        ELSIF i_action = pk_icnp_constant.g_action_interv_edit
        THEN
            -- g_action_interv_edit
            -- The algorithm is the same for all the intervention types 
            calc_st_for_edit();
        ELSIF i_action = pk_icnp_constant.g_action_interv_discont
        THEN
            -- g_action_interv_resolve
            -- The algorithm is the same for all the intervention types 
            calc_st_for_discont();
        END IF;
    
        -- When the new status is not resolved by the previous algorithm, something is wrong, so
        -- an exception must be thrown
        IF l_new_status = c_invalid_status
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_status_transition,
                                            text_in       => 'Unable to determine the new status when the action is ' ||
                                                             i_action || ', the current status is ' || i_interv_status ||
                                                             ', intervention type is ' || i_interv_type ||
                                                             ', has execs ' || pk_icnp_util.to_string(l_has_execs) ||
                                                             ', has planned execs ' ||
                                                             pk_icnp_util.to_string(l_has_planned_execs));
        END IF;
    
        RETURN l_new_status;
    
    END get_interv_status;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE INTERV]
    --------------------------------------------------------------------------------

    /**
     * Creates an icnp_epis_intervention record based in the input parameters and in 
     * some default values that should be set when a new record is created.
     *
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_interv The identifier of the intervention that we want to insert.
     * @param i_flg_type The type of frequency (once, no schedule or with recurrence).
     * @param i_flg_time Flag that indicates in which episode the task should be performed.
     * @param i_dt_begin_tstz Date that indicates when the task should be performed.
     * @param i_notes Notes of the intervention request.
     * @param i_order_recurr_plan Identifier of the recurrence plan.
     * @param i_flg_prn Flag that indicates if the intervention should only be executed as 
     *                  the situation demands.
     * @param i_prn_notes Notes to indicate the conditions under which the intervention 
     *                    should be executed.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return A icnp_epis_intervention record prepared to be inserted.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 06/Jun/2011
    */
    FUNCTION create_interv_row
    (
        i_prof              IN profissional,
        i_episode           IN icnp_epis_intervention.id_episode%TYPE,
        i_patient           IN icnp_epis_intervention.id_patient%TYPE,
        i_interv            IN icnp_epis_intervention.id_composition%TYPE,
        i_flg_type          IN icnp_epis_intervention.flg_type%TYPE,
        i_flg_time          IN icnp_epis_intervention.flg_time%TYPE,
        i_dt_begin_tstz     IN icnp_epis_intervention.dt_begin_tstz%TYPE,
        i_notes             IN icnp_epis_intervention.notes%TYPE,
        i_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE,
        i_flg_prn           IN icnp_epis_intervention.flg_prn%TYPE,
        i_prn_notes         IN icnp_epis_intervention.prn_notes%TYPE,
        i_sysdate_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN icnp_epis_intervention%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'CREATE_ICNP_INTERV_ROW';
        l_interv_row icnp_epis_intervention%ROWTYPE;
    
    BEGIN
        log_debug(c_func_name || '(i_prof:' || pk_icnp_util.to_string(i_prof) || ', i_episode:' || i_episode ||
                  ', i_patient:' || i_patient || ', i_sysdate_tstz:' || i_sysdate_tstz || ')',
                  c_func_name);
    
        l_interv_row.id_icnp_epis_interv      := ts_icnp_epis_intervention.next_key;
        l_interv_row.id_patient               := i_patient;
        l_interv_row.id_episode               := i_episode;
        l_interv_row.flg_type                 := i_flg_type;
        l_interv_row.flg_status               := pk_icnp_constant.g_epis_interv_status_requested;
        l_interv_row.id_prof                  := i_prof.id;
        l_interv_row.dt_icnp_epis_interv_tstz := i_sysdate_tstz;
        l_interv_row.id_episode_origin        := NULL;
        l_interv_row.id_prof_last_update      := i_prof.id;
        l_interv_row.dt_last_update           := i_sysdate_tstz;
        l_interv_row.id_composition           := i_interv;
        l_interv_row.notes                    := i_notes;
        l_interv_row.flg_time                 := i_flg_time;
        l_interv_row.id_order_recurr_plan     := i_order_recurr_plan;
        l_interv_row.flg_prn                  := i_flg_prn;
        l_interv_row.prn_notes                := i_prn_notes;
        l_interv_row.dt_begin_tstz            := i_dt_begin_tstz;
        l_interv_row.dt_next_tstz             := get_interv_dt_next_for_new_rec(i_flg_type      => i_flg_type,
                                                                                i_dt_begin_tstz => i_dt_begin_tstz);
    
        -- Non used values, since the implementation of the recurrence mechanism
        l_interv_row.num_take          := NULL;
        l_interv_row.interval          := NULL;
        l_interv_row.flg_interval_unit := NULL;
        l_interv_row.duration          := NULL;
        l_interv_row.flg_duration_unit := NULL;
        l_interv_row.dt_end_tstz       := NULL;
    
        RETURN l_interv_row;
    
    END create_interv_row;

    /**
     * Creates an ti_log record based in the input parameters and in some
     * default values that should be set when a new record is created.
     *
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_interv Identifier of the intervention that was inserted.
     * @param i_sysdate_tstz Timestamp used when the record icnp_epis_intervention was created.
     * 
     * @return A ti_log record prepared to be inserted.
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 27/Jul/2011
    */
    FUNCTION create_ti_interv_row
    (
        i_prof         IN profissional,
        i_episode      IN ti_log.id_episode%TYPE,
        i_interv       IN ti_log.id_record%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN ti_log%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_ti_interv_row';
        l_ti_log_row ti_log%ROWTYPE;
    
    BEGIN
        log_debug(c_func_name || '(i_prof:' || pk_icnp_util.to_string(i_prof) || ', i_episode:' || i_episode ||
                  ', i_interv:' || i_interv || ')',
                  c_func_name);
    
        l_ti_log_row.id_ti_log        := ts_ti_log.next_key;
        l_ti_log_row.id_professional  := i_prof.id;
        l_ti_log_row.id_episode       := i_episode;
        l_ti_log_row.flg_status       := pk_alert_constant.g_active;
        l_ti_log_row.id_record        := i_interv;
        l_ti_log_row.flg_type         := pk_icnp_constant.g_ti_log_type_interv;
        l_ti_log_row.dt_creation_tstz := i_sysdate_tstz;
    
        RETURN l_ti_log_row;
    
    END create_ti_interv_row;

    /**
     * Creates a set of intervention records (icnp_epis_intervention rows). Each 
     * record of the collection is a icnp_epis_intervention row already with the data
     * that should be persisted in the database.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode_id The episode identifier.
     * @param i_interv_row_coll Collection of icnp_epis_intervention rows already with 
     *                          the data that should be persisted in the database.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_intervs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_interv_row_coll IN ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        i_sysdate_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_intervs';
        -- Data structures related with ti_log
        l_ti_row_coll ts_ti_log.ti_log_tc;
        l_ti_rowids   table_varchar;
        -- Data structures related with icnp_epis_intervention
        l_epis_interv_row    icnp_epis_intervention%ROWTYPE;
        l_epis_interv_rowids table_varchar;
        -- Data structures related with error management
        l_error t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_interv_row_coll)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the intervention rows (i_interv_row_coll) given as input parameter is empty');
        END IF;
    
        -- Loop the interventions to create a collection of ti records (for further bulk processing)
        FOR i IN i_interv_row_coll.first .. i_interv_row_coll.last
        LOOP
            l_epis_interv_row := i_interv_row_coll(i);
            l_ti_row_coll(i) := create_ti_interv_row(i_prof         => i_prof,
                                                     i_episode      => l_epis_interv_row.id_episode,
                                                     i_interv       => l_epis_interv_row.id_icnp_epis_interv,
                                                     i_sysdate_tstz => i_sysdate_tstz);
        END LOOP;
    
        -- Persist the data into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_epis_intervention.ins(rows_in => i_interv_row_coll, rows_out => l_epis_interv_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_INTERVENTION',
                                      i_rowids     => l_epis_interv_rowids,
                                      o_error      => l_error);
    
        -- Persist the ti_log (interventions) into the database and brodcast the update 
        -- through the data governace mechanism
        ts_ti_log.ins(rows_in => l_ti_row_coll, rows_out => l_ti_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'TI_LOG',
                                      i_rowids     => l_ti_rowids,
                                      o_error      => l_error);
    
    END create_intervs;

    /**
     * Creates history records for all the interventions given as input parameter.
     * It is important to guarantee that before each update on an intervention 
     * record, a copy of the record is persisted. This is the mechanism we have
     * to present to the user all the changes made in the record through time.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_coll Interventions records whose history will be created.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_interv_hist  Identifiers list of the created history records.
     *
     * @author Pedro Carneiro
     * @version 2.5.1
     * @since 2010/07/22
    */
    PROCEDURE create_interv_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_coll  IN ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_interv_hist  OUT table_number
    ) IS
        -- Data structures related with icnp_epis_intervention
        l_interv_row icnp_epis_intervention%ROWTYPE;
        -- Data structures related with icnp_epis_intervention_hist
        l_interv_hist_row_coll ts_icnp_epis_intervention_hist.icnp_epis_intervention_hist_tc;
        l_interv_hist_row      icnp_epis_intervention_hist%ROWTYPE;
        l_interv_hist_ids      table_number := table_number();
        l_interv_hist_rowids   table_varchar;
        -- Data structures related with error management
        l_error t_error_out;
    
    BEGIN
        -- check input
        IF pk_icnp_util.is_table_empty(i_interv_coll)
        THEN
            o_interv_hist := table_number();
            RETURN;
        END IF;
    
        -- set author and date
        l_interv_hist_row.id_prof_created_hist := i_prof.id;
        l_interv_hist_row.dt_created_hist      := i_sysdate_tstz;
        -- for each retrieved record...
        FOR i IN i_interv_coll.first .. i_interv_coll.last
        LOOP
            -- current record
            l_interv_row := i_interv_coll(i);
            -- build history record
            SELECT seq_icnp_epis_interv_hist.nextval
              INTO l_interv_hist_row.id_icnp_epis_interv_hist
              FROM dual;
            l_interv_hist_row.id_icnp_epis_interv      := l_interv_row.id_icnp_epis_interv;
            l_interv_hist_row.id_patient               := l_interv_row.id_patient;
            l_interv_hist_row.id_episode               := l_interv_row.id_episode;
            l_interv_hist_row.id_composition           := l_interv_row.id_composition;
            l_interv_hist_row.flg_status               := l_interv_row.flg_status;
            l_interv_hist_row.notes                    := l_interv_row.notes;
            l_interv_hist_row.id_prof                  := l_interv_row.id_prof;
            l_interv_hist_row.notes_close              := l_interv_row.notes_close;
            l_interv_hist_row.id_prof_close            := l_interv_row.id_prof_close;
            l_interv_hist_row.forward_interv           := l_interv_row.forward_interv;
            l_interv_hist_row.notes_iteraction         := l_interv_row.notes_iteraction;
            l_interv_hist_row.notes_close_iteraction   := l_interv_row.notes_close_iteraction;
            l_interv_hist_row.flg_time                 := l_interv_row.flg_time;
            l_interv_hist_row.flg_type                 := l_interv_row.flg_type;
            l_interv_hist_row.dt_icnp_epis_interv_tstz := l_interv_row.dt_icnp_epis_interv_tstz;
            l_interv_hist_row.dt_begin_tstz            := l_interv_row.dt_begin_tstz;
            l_interv_hist_row.dt_end_tstz              := l_interv_row.dt_end_tstz;
            l_interv_hist_row.dt_next_tstz             := l_interv_row.dt_next_tstz;
            l_interv_hist_row.dt_close_tstz            := l_interv_row.dt_close_tstz;
            l_interv_hist_row.id_episode_origin        := l_interv_row.id_episode_origin;
            l_interv_hist_row.id_episode_destination   := l_interv_row.id_episode_destination;
            l_interv_hist_row.id_prof_last_update      := l_interv_row.id_prof_last_update;
            l_interv_hist_row.dt_last_update           := l_interv_row.dt_last_update;
            l_interv_hist_row.id_suspend_reason        := l_interv_row.id_suspend_reason;
            l_interv_hist_row.id_suspend_prof          := l_interv_row.id_suspend_prof;
            l_interv_hist_row.suspend_notes            := l_interv_row.suspend_notes;
            l_interv_hist_row.dt_suspend               := l_interv_row.dt_suspend;
            l_interv_hist_row.id_cancel_reason         := l_interv_row.id_cancel_reason;
            l_interv_hist_row.id_cancel_prof           := l_interv_row.id_cancel_prof;
            l_interv_hist_row.cancel_notes             := l_interv_row.cancel_notes;
            l_interv_hist_row.dt_cancel                := l_interv_row.dt_cancel;
            l_interv_hist_row.id_order_recurr_plan     := l_interv_row.id_order_recurr_plan;
            l_interv_hist_row.flg_prn                  := l_interv_row.flg_prn;
            l_interv_hist_row.prn_notes                := l_interv_row.prn_notes;
            -- add history record to collection
            l_interv_hist_row_coll(i) := l_interv_hist_row;
            -- add history record id to list
            l_interv_hist_ids.extend;
            l_interv_hist_ids(l_interv_hist_ids.last) := l_interv_hist_row.id_icnp_epis_interv_hist;
        END LOOP;
    
        -- set history
        ts_icnp_epis_intervention_hist.ins(rows_in => l_interv_hist_row_coll, rows_out => l_interv_hist_rowids);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_INTERVENTION_HIST',
                                      i_rowids     => l_interv_hist_rowids,
                                      o_error      => l_error);
    
        -- Set the output parameters
        o_interv_hist := l_interv_hist_ids;
    
    END create_interv_hist;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE INTERV ROW]
    --------------------------------------------------------------------------------

    /**
     * Updates a set of intervention records (icnp_epis_intervention rows). Each 
     * record of the collection is a icnp_epis_intervention row already with the data
     * that should be persisted in the database. The ALERT data governance mechanism
     * demands that whenever an update is executed an event with the rows and columns 
     * updated is broadcasted. For that purpose, a set of column names (i_cols) should
     * always be defined.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_row_coll Collection of icnp_epis_intervention rows already with 
     *                          the data that should be persisted in the database.
     * @param i_cols Set of column names that were updated.
     * 
     * @return Collection with the updated icnp_epis_intervention rowids.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_interv_rows
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_interv_row_coll    IN ts_icnp_epis_intervention.icnp_epis_intervention_tc,
        i_cols               IN table_varchar,
        o_interv_rowids_coll OUT table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_interv_rows';
        l_interv_rowids_coll table_varchar;
        l_error              t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_interv_row_coll)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the intervention rows (i_interv_row_coll) given as input parameter is empty');
        END IF;
        IF pk_icnp_util.is_table_empty(i_cols)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the column names (i_cols) given as input parameter is empty');
        END IF;
    
        -- Persist the data into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_epis_intervention.upd(col_in            => i_interv_row_coll,
                                      ignore_if_null_in => FALSE,
                                      rows_out          => l_interv_rowids_coll);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_EPIS_INTERVENTION',
                                      i_rowids       => l_interv_rowids_coll,
                                      o_error        => l_error,
                                      i_list_columns => i_cols);
    
        -- Set the output parameters
        o_interv_rowids_coll := l_interv_rowids_coll;
    
    END update_interv_rows;

    /**
     * Updates a intervention record (icnp_epis_intervention row). The icnp_epis_intervention 
     * row must already have the data that should be persisted in the database. The 
     * ALERT data governance mechanism demands that whenever an update is executed an 
     * event with the rows and columns updated is broadcasted. For that purpose, a set 
     * of column names (i_cols) should always be defined.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_row The icnp_epis_intervention row already with the data that
     *                     should be persisted in the database.
     * @param i_cols Set of column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_interv_row
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_interv_row IN icnp_epis_intervention%ROWTYPE,
        i_cols       IN table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_interv_row';
        l_interv_row_coll    ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Persist the data into the database
        l_interv_row_coll(1) := i_interv_row;
        update_interv_rows(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_interv_row_coll    => l_interv_row_coll,
                           i_cols               => i_cols,
                           o_interv_rowids_coll => l_interv_rowids_coll);
    
    END update_interv_row;

    --------------------------------------------------------------------------------
    -- METHODS [CHANGE ROW COLUMNS FOR UPDATE STATUS]
    --------------------------------------------------------------------------------

    /**
     * Updates all the necessary columns of an intervention record (icnp_epis_intervention row)
     * when the user resolves an intervention. A set with the column names that
     * were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_interv_row The icnp_epis_intervention row whose columns will be 
     *                      updated. This is an input/output argument because the
     *                      intervention record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_interv_row_resolve_cols
    (
        i_prof         IN profissional,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_interv_row  IN OUT NOCOPY icnp_epis_intervention%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_interv_row_resolve_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the intervention record
        io_interv_row.flg_status          := get_interv_status(i_epis_interv_id => io_interv_row.id_icnp_epis_interv,
                                                               i_interv_type    => io_interv_row.flg_type,
                                                               i_interv_status  => io_interv_row.flg_status,
                                                               i_action         => pk_icnp_constant.g_action_interv_resolve);
        io_interv_row.dt_end_tstz         := i_sysdate_tstz;
        io_interv_row.dt_next_tstz        := NULL;
        io_interv_row.id_prof_last_update := i_prof.id;
        io_interv_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'DT_END_TSTZ', 'DT_NEXT_TSTZ', 'ID_PROF_LAST_UPDATE', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_interv_row_resolve_cols;

    /**
     * Updates all the necessary columns of an intervention record (icnp_epis_intervention row)
     * when the user pauses an intervention. A set with the column names that
     * were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_suspend_reason Suspension reason identifier.
     * @param i_suspend_notes Notes describing the reason of the suspension.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_interv_row The icnp_epis_intervention row whose columns will be 
     *                      updated. This is an input/output argument because the
     *                      intervention record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_interv_row_pause_cols
    (
        i_prof           IN profissional,
        i_suspend_reason IN icnp_epis_intervention.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_intervention.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_interv_row    IN OUT NOCOPY icnp_epis_intervention%ROWTYPE,
        i_force_status   IN VARCHAR2 DEFAULT 'N'
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_interv_row_pause_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the intervention record
        io_interv_row.flg_status          := get_interv_status(i_epis_interv_id => io_interv_row.id_icnp_epis_interv,
                                                               i_interv_type    => io_interv_row.flg_type,
                                                               i_interv_status  => io_interv_row.flg_status,
                                                               i_action         => pk_icnp_constant.g_action_interv_pause,
                                                               i_force_status   => i_force_status);
        io_interv_row.id_suspend_prof     := i_prof.id;
        io_interv_row.dt_suspend          := i_sysdate_tstz;
        io_interv_row.id_suspend_reason   := i_suspend_reason;
        io_interv_row.suspend_notes       := i_suspend_notes;
        io_interv_row.dt_next_tstz        := NULL;
        io_interv_row.id_prof_last_update := i_prof.id;
        io_interv_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS',
                                'ID_SUSPEND_PROF',
                                'DT_SUSPEND',
                                'ID_SUSPEND_REASON',
                                'SUSPEND_NOTES',
                                'DT_NEXT_TSTZ',
                                'ID_PROF_LAST_UPDATE',
                                'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_interv_row_pause_cols;

    /**
     * Updates all the necessary columns of an intervention record (icnp_epis_intervention row)
     * when the user resumes an intervention. A set with the column names that
     * were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_interv_row The icnp_epis_intervention row whose columns will be 
     *                      updated. This is an input/output argument because the
     *                      intervention record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_interv_row_resume_cols
    (
        i_prof         IN profissional,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_interv_row  IN OUT NOCOPY icnp_epis_intervention%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_interv_row_resume_cols';
        l_exec_row icnp_interv_plan%ROWTYPE;
        l_cols     table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the intervention record
        io_interv_row.flg_status          := get_interv_status(i_epis_interv_id => io_interv_row.id_icnp_epis_interv,
                                                               i_interv_type    => io_interv_row.flg_type,
                                                               i_interv_status  => io_interv_row.flg_status,
                                                               i_action         => pk_icnp_constant.g_action_interv_resume);
        l_exec_row                        := get_interv_next_exec_row(i_epis_interv_id => io_interv_row.id_icnp_epis_interv);
        io_interv_row.dt_next_tstz        := l_exec_row.dt_plan_tstz;
        io_interv_row.id_prof_last_update := i_prof.id;
        io_interv_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'DT_NEXT_TSTZ', 'ID_PROF_LAST_UPDATE', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_interv_row_resume_cols;

    /**
     * Updates all the necessary columns of an intervention record (icnp_epis_intervention row)
     * when the user edits an intervention. A set with the column names that
     * were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_flg_type The type of frequency (once, no schedule or with recurrence).
     * @param i_flg_time Flag that indicates in which episode the task should be performed.
     * @param i_dt_begin_tstz Date that indicates when the task should be performed.
     * @param i_notes Notes of the intervention request.
     * @param i_order_recurr_plan Identifier of the recurrence plan.
     * @param i_flg_prn Flag that indicates if the intervention should only be executed as 
     *                  the situation demands.
     * @param i_prn_notes Notes to indicate the conditions under which the intervention 
     *                    should be executed.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_interv_row The icnp_epis_intervention row whose columns will be 
     *                      updated. This is an input/output argument because the
     *                      intervention record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 25/Jul/2011 (v2.6.1)
    */
    FUNCTION change_interv_row_edit_cols
    (
        i_prof              IN profissional,
        i_episode           IN icnp_epis_intervention.id_episode%TYPE,
        i_flg_type          IN icnp_epis_intervention.flg_type%TYPE,
        i_flg_time          IN icnp_epis_intervention.flg_time%TYPE,
        i_dt_begin_tstz     IN icnp_epis_intervention.dt_begin_tstz%TYPE,
        i_notes             IN icnp_epis_intervention.notes%TYPE,
        i_order_recurr_plan IN icnp_epis_intervention.id_order_recurr_plan%TYPE,
        i_flg_prn           IN icnp_epis_intervention.flg_prn%TYPE,
        i_prn_notes         IN icnp_epis_intervention.prn_notes%TYPE,
        i_sysdate_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_interv_row       IN OUT NOCOPY icnp_epis_intervention%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_interv_row_edit_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the intervention record
        io_interv_row.flg_status               := get_interv_status(i_epis_interv_id => io_interv_row.id_icnp_epis_interv,
                                                                    i_interv_type    => io_interv_row.flg_type,
                                                                    i_interv_status  => io_interv_row.flg_status,
                                                                    i_action         => pk_icnp_constant.g_action_interv_edit);
        io_interv_row.id_episode               := i_episode;
        io_interv_row.id_prof                  := i_prof.id;
        io_interv_row.dt_icnp_epis_interv_tstz := i_sysdate_tstz;
        io_interv_row.id_episode_origin        := NULL;
        io_interv_row.flg_type                 := i_flg_type;
        io_interv_row.flg_time                 := i_flg_time;
        io_interv_row.dt_begin_tstz            := i_dt_begin_tstz;
        io_interv_row.dt_next_tstz             := get_interv_dt_next_for_new_rec(i_flg_type      => i_flg_type,
                                                                                 i_dt_begin_tstz => i_dt_begin_tstz);
        io_interv_row.notes                    := i_notes;
        io_interv_row.id_order_recurr_plan     := i_order_recurr_plan;
        io_interv_row.flg_prn                  := i_flg_prn;
        io_interv_row.prn_notes                := i_prn_notes;
        io_interv_row.id_prof_last_update      := i_prof.id;
        io_interv_row.dt_last_update           := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('ID_EPISODE',
                                'ID_PROF',
                                'DT_ICNP_EPIS_INTERV_TSTZ',
                                'ID_EPISODE_ORIGIN',
                                'FLG_TYPE',
                                'FLG_STATUS',
                                'FLG_TIME',
                                'DT_BEGIN_TSTZ',
                                'DT_NEXT_TSTZ',
                                'NOTES',
                                'ID_ORDER_RECURR_PLAN',
                                'FLG_PRN',
                                'PRN_NOTES',
                                'ID_PROF_LAST_UPDATE',
                                'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_interv_row_edit_cols;

    /**
     * Updates all the necessary columns of an intervention record (icnp_epis_intervention row)
     * when the user cancels an intervention. A set with the column names that
     * were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_interv_row The icnp_epis_intervention row whose columns will be 
     *                      updated. This is an input/output argument because the
     *                      intervention record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_interv_row_cancel_cols
    (
        i_prof          IN profissional,
        i_cancel_reason IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_interv_row   IN OUT NOCOPY icnp_epis_intervention%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_interv_row_cancel_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the intervention record
        io_interv_row.flg_status          := get_interv_status(i_epis_interv_id => io_interv_row.id_icnp_epis_interv,
                                                               i_interv_type    => io_interv_row.flg_type,
                                                               i_interv_status  => io_interv_row.flg_status,
                                                               i_action         => pk_icnp_constant.g_action_interv_cancel);
        io_interv_row.id_cancel_prof      := i_prof.id;
        io_interv_row.dt_cancel           := i_sysdate_tstz;
        io_interv_row.dt_close_tstz       := i_sysdate_tstz;
        io_interv_row.id_cancel_reason    := i_cancel_reason;
        io_interv_row.cancel_notes        := i_cancel_notes;
        io_interv_row.dt_next_tstz        := NULL;
        io_interv_row.id_prof_last_update := i_prof.id;
        io_interv_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS',
                                'ID_CANCEL_PROF',
                                'DT_CANCEL',
                                'ID_CANCEL_REASON',
                                'CANCEL_NOTES',
                                'DT_NEXT_TSTZ',
                                'ID_PROF_LAST_UPDATE',
                                'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_interv_row_cancel_cols;

    FUNCTION change_interv_row_finish_cols
    (
        i_prof         IN profissional,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_interv_row  IN OUT NOCOPY icnp_epis_intervention%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_interv_row_cancel_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the intervention record
        io_interv_row.flg_status          := pk_icnp_constant.g_epis_interv_status_executed;
        io_interv_row.dt_close_tstz       := i_sysdate_tstz;
        io_interv_row.dt_next_tstz        := NULL;
        io_interv_row.id_prof_last_update := i_prof.id;
        io_interv_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'DT_NEXT_TSTZ', 'ID_PROF_LAST_UPDATE', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_interv_row_finish_cols;

    /**
     * Updates the status and the next execution date of an intervention record 
     * (icnp_epis_intervention row). A set with the column names that were updated 
     * is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_action An action performed by the user that caused the status change.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_interv_row The icnp_epis_intervention row whose columns will be 
     *                      updated. This is an input/output argument because the
     *                      intervention record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_int_row_statdtnext_cols
    (
        i_prof         IN profissional,
        i_action       IN action.code_action%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_interv_row  IN OUT NOCOPY icnp_epis_intervention%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_int_row_statdtnext_cols';
        l_exec_row icnp_interv_plan%ROWTYPE;
        l_cols     table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the intervention record
        l_exec_row                        := get_interv_next_exec_row(i_epis_interv_id => io_interv_row.id_icnp_epis_interv);
        io_interv_row.flg_status          := get_interv_status(i_epis_interv_id => io_interv_row.id_icnp_epis_interv,
                                                               i_interv_type    => io_interv_row.flg_type,
                                                               i_interv_status  => io_interv_row.flg_status,
                                                               i_action         => i_action);
        io_interv_row.dt_next_tstz        := l_exec_row.dt_plan_tstz;
        io_interv_row.id_prof_last_update := i_prof.id;
        io_interv_row.dt_last_update      := i_sysdate_tstz;
        IF io_interv_row.flg_status = pk_icnp_constant.g_epis_interv_status_executed
        THEN
            io_interv_row.dt_close_tstz := i_sysdate_tstz;
        END IF;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'DT_NEXT_TSTZ', 'ID_PROF_LAST_UPDATE', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_int_row_statdtnext_cols;

    /**
     * Updates all the necessary columns of an intervention record (icnp_epis_intervention row)
     * when the user resolves an intervention. A set with the column names that
     * were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_interv_row The icnp_epis_intervention row whose columns will be 
     *                      updated. This is an input/output argument because the
     *                      intervention record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Nuno Neves
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_interv_row_discont_cols
    (
        i_prof         IN profissional,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_interv_row  IN OUT NOCOPY icnp_epis_intervention%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_interv_row_discont_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the intervention record
        io_interv_row.flg_status          := get_interv_status(i_epis_interv_id => io_interv_row.id_icnp_epis_interv,
                                                               i_interv_type    => io_interv_row.flg_type,
                                                               i_interv_status  => io_interv_row.flg_status,
                                                               i_action         => pk_icnp_constant.g_action_interv_discont);
        io_interv_row.dt_end_tstz         := i_sysdate_tstz;
        io_interv_row.dt_next_tstz        := NULL;
        io_interv_row.id_prof_last_update := i_prof.id;
        io_interv_row.dt_last_update      := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'DT_END_TSTZ', 'DT_NEXT_TSTZ', 'ID_PROF_LAST_UPDATE', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_interv_row_discont_cols;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE INTERV STATUS UTIL]
    --------------------------------------------------------------------------------

    /**
     * Checks if, when updating a set of interventions, the number of updated records
     * matches the number of historical records created.
     * 
     * @param i_interv_rows_updated Number of updated intervention records.
     * @param i_interv_hist_rows_created Number of historical records created.
     * 
     * @see create_interv_hist 
     * @see set_intervs_status_*
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    PROCEDURE check_interv_and_hist_count
    (
        i_interv_rows_updated      IN NUMBER,
        i_interv_hist_rows_created IN NUMBER
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'check_interv_and_hist_count';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        IF i_interv_rows_updated != i_interv_hist_rows_created
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_count_mismatch,
                                            text_in       => 'Count mismatch: updated ' || i_interv_rows_updated ||
                                                             ' intervention record(s), created ' ||
                                                             i_interv_hist_rows_created || ' history record(s)');
        END IF;
    
    END check_interv_and_hist_count;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE INTERV STATUS]
    --------------------------------------------------------------------------------

    /**
     * Makes the necessary updates to an intervention record (icnp_epis_intervention row)
     * when the user resolves an intervention. A resolved intervention is considered
     * completed, the user can't make any more executions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention that we want to 
     *                         resolve.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_status_resolve
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_status_resolve';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Resolve the intervention
        set_intervs_status_resolve(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_interv_ids   => table_number(i_epis_interv_id),
                                   i_sysdate_tstz => i_sysdate_tstz);
    
    END set_interv_status_resolve;

    /**
     * Makes the necessary updates to a set of intervention records 
     * (icnp_epis_intervention rows) when the user resolves the interventions. A 
     * resolved intervention is considered completed, the user can't make any more 
     * executions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of identifiers of the interventions that we want 
     *                     to resolve.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_intervs_status_resolve
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_intervs_status_resolve';
        l_interv_row         icnp_epis_intervention%ROWTYPE;
        l_interv_row_coll    ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_cols               table_varchar;
        l_interv_hist        table_number;
        l_interv_rowids_coll table_varchar;
        l_count              NUMBER;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_interv_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            RETURN;
        END IF;
    
        -- Marks as not executed all the execution records that are not yet executed
        pk_icnp_exec.set_exec_st_notexe_for_intervs(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_interv_ids   => i_interv_ids,
                                                    i_sysdate_tstz => i_sysdate_tstz);
    
        -- Gets the intervention rows of all the ids
        l_interv_row_coll := get_interv_rows(i_interv_ids => i_interv_ids);
    
        -- Creates history records for all the interventions
        create_interv_hist(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_interv_coll  => l_interv_row_coll,
                           i_sysdate_tstz => i_sysdate_tstz,
                           o_interv_hist  => l_interv_hist);
    
        -- Make the necessary changes to each intervention record in the collection
        FOR i IN l_interv_row_coll.first .. l_interv_row_coll.last
        LOOP
            l_interv_row := l_interv_row_coll(i);
        
            SELECT COUNT(iip.id_icnp_epis_interv)
              INTO l_count
              FROM icnp_interv_plan iip
             WHERE iip.id_icnp_epis_interv = l_interv_row.id_icnp_epis_interv
               AND iip.flg_status IN
                   (pk_icnp_constant.g_interv_plan_status_executed, pk_icnp_constant.g_interv_plan_status_ongoing);
        
            IF l_count > 0
            THEN
                l_cols := change_interv_row_discont_cols(i_prof         => i_prof,
                                                         i_sysdate_tstz => i_sysdate_tstz,
                                                         io_interv_row  => l_interv_row);
            ELSE
            
                /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
                 * is to have a new method, invoked outside the loop, that only returns the changed 
                 * columns. This could be, although, more error prone because the developer could 
                 * easily forget to update both methods.
                */
                l_cols := change_interv_row_resolve_cols(i_prof         => i_prof,
                                                         i_sysdate_tstz => i_sysdate_tstz,
                                                         io_interv_row  => l_interv_row);
            END IF;
            l_interv_row_coll(i) := l_interv_row;
        END LOOP;
    
        -- Persist the data into the database
        update_interv_rows(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_interv_row_coll    => l_interv_row_coll,
                           i_cols               => l_cols,
                           o_interv_rowids_coll => l_interv_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_interv_and_hist_count(i_interv_rows_updated      => l_interv_rowids_coll.count,
                                    i_interv_hist_rows_created => l_interv_hist.count);
    
    END set_intervs_status_resolve;

    /**
     * Makes the necessary updates to an intervention record (icnp_epis_intervention row)
     * when the user pauses an intervention. When the intervention is paused no 
     * executions could be made, until the intervention is resumed again. Under
     * this circumstances we don't have the concept of "next execution".
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention that we want o pause.
     * @param i_suspend_reason Suspension reason identifier.
     * @param i_suspend_notes Notes describing the reason of the suspension.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_status_pause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_suspend_reason IN icnp_epis_intervention.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_intervention.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_status_pause';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Pause the intervention
        set_intervs_status_pause(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_interv_ids     => table_number(i_epis_interv_id),
                                 i_suspend_reason => i_suspend_reason,
                                 i_suspend_notes  => i_suspend_notes,
                                 i_sysdate_tstz   => i_sysdate_tstz);
    
    END set_interv_status_pause;

    /**
     * Makes the necessary updates to a set of intervention records 
     * (icnp_epis_intervention rows) when the user pauses the interventions. When 
     * the intervention is paused no executions could be made, until the intervention 
     * is resumed again. Under this circumstances we don't have the concept of 
     * "next execution".
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of identifiers of the interventions that we want 
     *                     to pause.
     * @param i_suspend_reason Suspension reason identifier.
     * @param i_suspend_notes Notes describing the reason of the suspension.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_intervs_status_pause
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_interv_ids     IN table_number,
        i_suspend_reason IN icnp_epis_intervention.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_intervention.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_force_status   IN VARCHAR2 DEFAULT 'N'
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_intervs_status_pause';
        l_interv_row         icnp_epis_intervention%ROWTYPE;
        l_interv_row_coll    ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_cols               table_varchar;
        l_interv_hist        table_number;
        l_interv_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_interv_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            RETURN;
        END IF;
    
        -- Marks as suspended all the execution records that are not yet executed
        pk_icnp_exec.set_exec_st_susp_for_intervs(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_interv_ids   => i_interv_ids,
                                                  i_sysdate_tstz => i_sysdate_tstz);
    
        -- Gets the intervention rows of all the ids
        l_interv_row_coll := get_interv_rows(i_interv_ids => i_interv_ids);
    
        -- Creates history records for all the interventions
        create_interv_hist(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_interv_coll  => l_interv_row_coll,
                           i_sysdate_tstz => i_sysdate_tstz,
                           o_interv_hist  => l_interv_hist);
    
        -- Make the necessary changes to each intervention record in the collection
        FOR i IN l_interv_row_coll.first .. l_interv_row_coll.last
        LOOP
            l_interv_row := l_interv_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_interv_row_pause_cols(i_prof           => i_prof,
                                                   i_suspend_reason => i_suspend_reason,
                                                   i_suspend_notes  => i_suspend_notes,
                                                   i_sysdate_tstz   => i_sysdate_tstz,
                                                   io_interv_row    => l_interv_row,
                                                   i_force_status   => i_force_status);
        
            l_interv_row_coll(i) := l_interv_row;
        END LOOP;
    
        -- Persist the data into the database
        update_interv_rows(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_interv_row_coll    => l_interv_row_coll,
                           i_cols               => l_cols,
                           o_interv_rowids_coll => l_interv_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_interv_and_hist_count(i_interv_rows_updated      => l_interv_rowids_coll.count,
                                    i_interv_hist_rows_created => l_interv_hist.count);
    
    END set_intervs_status_pause;

    /**
     * Makes the necessary updates to an intervention record (icnp_epis_intervention row)
     * when the user resumes an intervention. When the intervention is resumed it goes
     * again to its previous status before being paused and the user is allowed to make
     * executions again.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention that we want to resume.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_status_resume
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_status_resume';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Resume the intervention
        set_intervs_status_resume(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_interv_ids   => table_number(i_epis_interv_id),
                                  i_sysdate_tstz => i_sysdate_tstz);
    
    END set_interv_status_resume;

    /**
     * Makes the necessary updates to a set of intervention records 
     * (icnp_epis_intervention rows) when the user resumes the interventions. When 
     * the intervention is resumed it goes again to its previous status before being 
     * paused and the user is allowed to make executions again.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of identifiers of the interventions that we want 
     *                     to resume.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_intervs_status_resume
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_intervs_status_resume';
        l_interv_row         icnp_epis_intervention%ROWTYPE;
        l_interv_row_coll    ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_cols               table_varchar;
        l_interv_hist        table_number;
        l_interv_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_interv_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            RETURN;
        END IF;
    
        -- Marks as requested (active) all the execution records that are suspended
        pk_icnp_exec.set_exec_st_req_for_intervs(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_interv_ids   => i_interv_ids,
                                                 i_sysdate_tstz => i_sysdate_tstz);
    
        -- Gets the intervention rows of all the ids
        l_interv_row_coll := get_interv_rows(i_interv_ids => i_interv_ids);
    
        -- Creates history records for all the interventions
        create_interv_hist(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_interv_coll  => l_interv_row_coll,
                           i_sysdate_tstz => i_sysdate_tstz,
                           o_interv_hist  => l_interv_hist);
    
        -- Make the necessary changes to each intervention record in the collection
        FOR i IN l_interv_row_coll.first .. l_interv_row_coll.last
        LOOP
            l_interv_row := l_interv_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_interv_row_resume_cols(i_prof         => i_prof,
                                                    i_sysdate_tstz => i_sysdate_tstz,
                                                    io_interv_row  => l_interv_row);
        
            l_interv_row_coll(i) := l_interv_row;
        END LOOP;
    
        -- Persist the data into the database
        update_interv_rows(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_interv_row_coll    => l_interv_row_coll,
                           i_cols               => l_cols,
                           o_interv_rowids_coll => l_interv_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_interv_and_hist_count(i_interv_rows_updated      => l_interv_rowids_coll.count,
                                    i_interv_hist_rows_created => l_interv_hist.count);
    
    END set_intervs_status_resume;

    /**
     * Makes the necessary updates to an intervention record (icnp_epis_intervention row)
     * when the user cancels an intervention. When the intervention is cancelled the user
     * can't make any more executions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention that we want to cancel.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_status_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_cancel_reason  IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_status_cancel';
        l_exist              NUMBER;
        l_interv_rowids_coll table_varchar;
        l_error              t_error_out;
    
        l_flg_status      icnp_epis_diag_interv.flg_status%TYPE;
        l_interv_row_coll ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc;
        l_iedi_row_coll   icnp_epis_diag_interv%ROWTYPE;
    
        l_count PLS_INTEGER;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
        BEGIN
            SELECT 1
              INTO l_exist
              FROM icnp_suggest_interv isi
             WHERE isi.id_icnp_epis_interv = i_epis_interv_id
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_exist := 0;
        END;
        DECLARE
            e_already_exists EXCEPTION;
            PRAGMA EXCEPTION_INIT(e_already_exists, -01422);
        BEGIN
            SELECT iedi.flg_status
              INTO l_flg_status
              FROM icnp_epis_diag_interv iedi
             WHERE iedi.id_icnp_epis_interv = i_epis_interv_id;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_status := 'I';
            WHEN e_already_exists THEN
                l_flg_status := 'A';
            
        END;
    
        IF l_exist <> 1
           OR (l_exist = 1 AND l_flg_status = 'I')
        THEN
            -- Cancel the intervention
            set_intervs_status_cancel(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_interv_ids    => table_number(i_epis_interv_id),
                                      i_cancel_reason => i_cancel_reason,
                                      i_cancel_notes  => i_cancel_notes,
                                      i_sysdate_tstz  => i_sysdate_tstz);
        ELSE
            ts_icnp_epis_diag_interv.upd(flg_status_in      => 'I',
                                         dt_inactivation_in => i_sysdate_tstz,
                                         id_prof_assoc_in   => i_prof.id,
                                         where_in           => ' ID_ICNP_EPIS_INTERV = ' || i_epis_interv_id,
                                         rows_out           => l_interv_rowids_coll);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ICNP_EPIS_DIAG_INTERV',
                                          i_rowids     => l_interv_rowids_coll,
                                          o_error      => l_error);
        END IF;
    
        SELECT COUNT(1)
          INTO l_count
          FROM icnp_epis_intervention iei
         WHERE iei.id_order_recurr_plan IN
               (SELECT i.id_order_recurr_plan
                  FROM icnp_epis_intervention i
                 WHERE i.id_icnp_epis_interv = i_epis_interv_id)
           AND iei.flg_status NOT IN (pk_icnp_constant.g_epis_interv_status_cancelled,
                                      pk_icnp_constant.g_epis_interv_status_executed,
                                      pk_icnp_constant.g_epis_interv_status_discont)
           AND iei.id_order_recurr_plan IS NOT NULL;
    
        IF l_count = 0
        THEN
            UPDATE order_recurr_control orc
               SET orc.flg_status = 'F'
             WHERE orc.id_order_recurr_plan IN
                   (SELECT i.id_order_recurr_plan
                      FROM icnp_epis_intervention i
                     WHERE i.id_icnp_epis_interv = i_epis_interv_id);
        END IF;
    
        IF l_interv_rowids_coll IS NOT NULL
        THEN
            l_interv_row_coll := get_iedi_rows(i_interv_ids => table_number(i_epis_interv_id));
            FOR x IN 1 .. l_interv_row_coll.count
            LOOP
                l_iedi_row_coll := l_interv_row_coll(x);
            
                ts_icnp_epis_dg_int_hist.ins(id_icnp_epis_dg_int_hist_in => ts_icnp_epis_dg_int_hist.next_key,
                                             id_icnp_epis_diag_interv_in => l_iedi_row_coll.id_icnp_epis_diag_interv,
                                             id_icnp_epis_diag_in        => l_iedi_row_coll.id_icnp_epis_diag,
                                             id_icnp_epis_interv_in      => l_iedi_row_coll.id_icnp_epis_interv,
                                             flg_status_in               => 'I',
                                             dt_inactivation_in          => i_sysdate_tstz,
                                             dt_hist_in                  => current_timestamp,
                                             flg_iud_in                  => 'U', --UPDATE
                                             id_prof_assoc_in            => i_prof.id,
                                             rows_out                    => l_interv_rowids_coll);
            
            END LOOP;
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ICNP_EPIS_DG_INT_HIST',
                                          i_rowids     => l_interv_rowids_coll,
                                          o_error      => l_error);
        
        END IF;
    
    END set_interv_status_cancel;

    /**
     * Makes the necessary updates to a set of intervention records 
     * (icnp_epis_intervention rows) when the user cancels the interventions. When
     * the intervention is cancelled the user can't make any more executions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of identifiers of the interventions that we want 
     *                     to cancel.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_intervs_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_interv_ids    IN table_number,
        i_cancel_reason IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_intervs_status_cancel';
        l_interv_row         icnp_epis_intervention%ROWTYPE;
        l_interv_row_coll    ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_cols               table_varchar;
        l_interv_hist        table_number;
        l_interv_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_interv_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            RETURN;
        END IF;
    
        -- Marks as cancelled all the execution records that are not yet executed
        pk_icnp_exec.set_exec_st_cancel_for_intervs(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_interv_ids    => i_interv_ids,
                                                    i_cancel_reason => i_cancel_reason,
                                                    i_cancel_notes  => i_cancel_notes,
                                                    i_sysdate_tstz  => i_sysdate_tstz);
    
        -- Gets the intervention rows of all the ids
        l_interv_row_coll := get_interv_rows(i_interv_ids => i_interv_ids);
    
        -- Creates history records for all the interventions
        create_interv_hist(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_interv_coll  => l_interv_row_coll,
                           i_sysdate_tstz => i_sysdate_tstz,
                           o_interv_hist  => l_interv_hist);
    
        -- Make the necessary changes to each intervention record in the collection
        IF l_interv_row_coll IS NOT NULL
        THEN
            FOR i IN l_interv_row_coll.first .. l_interv_row_coll.last
            LOOP
                l_interv_row := l_interv_row_coll(i);
            
                /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
                 * is to have a new method, invoked outside the loop, that only returns the changed 
                 * columns. This could be, although, more error prone because the developer could 
                 * easily forget to update both methods.
                */
                l_cols := change_interv_row_cancel_cols(i_prof          => i_prof,
                                                        i_cancel_reason => i_cancel_reason,
                                                        i_cancel_notes  => i_cancel_notes,
                                                        i_sysdate_tstz  => i_sysdate_tstz,
                                                        io_interv_row   => l_interv_row);
            
                l_interv_row_coll(i) := l_interv_row;
            END LOOP;
        END IF;
    
        -- Persist the data into the database
        update_interv_rows(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_interv_row_coll    => l_interv_row_coll,
                           i_cols               => l_cols,
                           o_interv_rowids_coll => l_interv_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_interv_and_hist_count(i_interv_rows_updated      => l_interv_rowids_coll.count,
                                    i_interv_hist_rows_created => l_interv_hist.count);
    
    END set_intervs_status_cancel;

    PROCEDURE set_intervs_status_finish
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_intervs_status_cancel';
        l_interv_row         icnp_epis_intervention%ROWTYPE;
        l_interv_row_coll    ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_cols               table_varchar;
        l_interv_hist        table_number;
        l_interv_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_interv_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            RETURN;
        END IF;
    
        -- Marks as cancelled all the execution records that are not yet executed
        pk_icnp_exec.set_exec_st_cancel_for_intervs(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_interv_ids    => i_interv_ids,
                                                    i_cancel_reason => NULL,
                                                    i_cancel_notes  => NULL,
                                                    i_sysdate_tstz  => i_sysdate_tstz);
    
        -- Gets the intervention rows of all the ids
        l_interv_row_coll := get_interv_rows(i_interv_ids => i_interv_ids);
    
        -- Creates history records for all the interventions
        create_interv_hist(i_lang         => i_lang,
                           i_prof         => i_prof,
                           i_interv_coll  => l_interv_row_coll,
                           i_sysdate_tstz => i_sysdate_tstz,
                           o_interv_hist  => l_interv_hist);
    
        -- Make the necessary changes to each intervention record in the collection
        IF l_interv_row_coll IS NOT NULL
        THEN
            FOR i IN l_interv_row_coll.first .. l_interv_row_coll.last
            LOOP
                l_interv_row := l_interv_row_coll(i);
            
                /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
                 * is to have a new method, invoked outside the loop, that only returns the changed 
                 * columns. This could be, although, more error prone because the developer could 
                 * easily forget to update both methods.
                */
                l_cols := change_interv_row_finish_cols(i_prof         => i_prof,
                                                        i_sysdate_tstz => i_sysdate_tstz,
                                                        io_interv_row  => l_interv_row);
            
                l_interv_row_coll(i) := l_interv_row;
            END LOOP;
        END IF;
    
        -- Persist the data into the database
        update_interv_rows(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_interv_row_coll    => l_interv_row_coll,
                           i_cols               => l_cols,
                           o_interv_rowids_coll => l_interv_rowids_coll);
    
        -- Checks if the number of updated records matches the number of historical
        -- records created
        check_interv_and_hist_count(i_interv_rows_updated      => l_interv_rowids_coll.count,
                                    i_interv_hist_rows_created => l_interv_hist.count);
    
    END set_intervs_status_finish;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE INTERV STATUS FOR DIAG]
    --------------------------------------------------------------------------------

    /**
     * Gets a collection of intervention identifiers that are related with a set of
     * diagnosis. Only a subset of all the related interventions are returned, 
     * because:
     * 1) only interventions with id_episode_destination=NULL are returned;
     * 2) only interventions with some status (given as input) are returned.
     * 
     * For the reasons expressed above, this method should only be used by the
     * set_interv_st_xxx_for_diags methods.
     * 
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_status Set of intervention status used to filter the returned 
     *                 interventions.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION get_intervs_gen_for_diags
    (
        i_diag_ids IN table_number,
        i_status   IN table_varchar
    ) RETURN table_number IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_intervs_gen_for_diags';
        l_interv_ids table_number;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_status)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the status (i_status) given as input parameter is empty');
        END IF;
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN table_number();
        END IF;
    
        -- Retrieve the set of interventions
        SELECT aux.id_icnp_epis_interv
          BULK COLLECT
          INTO l_interv_ids
          FROM (SELECT iedi.id_icnp_epis_interv
                  FROM icnp_epis_diag_interv iedi
                  JOIN icnp_epis_intervention iei
                    ON iedi.id_icnp_epis_interv = iei.id_icnp_epis_interv
                 WHERE iedi.id_icnp_epis_diag IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                   t.column_value id_icnp_epis_diag
                                                    FROM TABLE(i_diag_ids) t)
                   AND iei.id_episode_destination IS NULL
                   AND iedi.id_icnp_epis_interv NOT IN
                       (SELECT isi.id_icnp_epis_interv
                          FROM icnp_suggest_interv isi
                         WHERE isi.id_icnp_epis_interv = iedi.id_icnp_epis_interv)
                   AND iei.flg_status IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           t.column_value flg_status
                                            FROM TABLE(i_status) t)
                UNION ALL
                SELECT iedi.id_icnp_epis_interv
                  FROM icnp_epis_diag_interv iedi
                  JOIN icnp_epis_intervention iei
                    ON iedi.id_icnp_epis_interv = iei.id_icnp_epis_interv
                 WHERE iedi.id_icnp_epis_diag IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                   t.column_value id_icnp_epis_diag
                                                    FROM TABLE(i_diag_ids) t)
                   AND iedi.flg_status_rel NOT IN (pk_icnp_constant.g_interv_rel_cancel)
                   AND iei.id_episode_destination IS NULL
                   AND EXISTS (SELECT 1
                          FROM icnp_suggest_interv isi
                         WHERE isi.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                        /*AND isi.flg_status != pk_icnp_constant.g_sug_interv_status_accepted*/
                        )
                   AND iei.flg_status IN (SELECT /*+opt_estimate(table t rows=1)*/
                                           t.column_value flg_status
                                            FROM TABLE(i_status) t)) aux;
    
        RETURN l_interv_ids;
    
    END get_intervs_gen_for_diags;

    /**
     * Resolves all the intervention records that are related with a set of
     * diagnosis. Usually this method is invoked when some action is performed
     * on the diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_intervs_status_resolve
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_st_resol_for_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_st_resol_for_diags';
        l_status     table_varchar;
        l_interv_ids table_number;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the interventions associated with the diagnosis that must be updated
        l_status     := table_varchar(pk_icnp_constant.g_epis_interv_status_requested,
                                      pk_icnp_constant.g_epis_interv_status_ongoing,
                                      pk_icnp_constant.g_epis_interv_status_suspended);
        l_interv_ids := get_intervs_gen_for_diags(i_diag_ids => i_diag_ids, i_status => l_status);
    
        -- Resolve the interventions associated with the diagnosis
        set_intervs_status_resolve(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_interv_ids   => l_interv_ids,
                                   i_sysdate_tstz => i_sysdate_tstz);
    
    END set_interv_st_resol_for_diags;

    /**
     * Pauses all the intervention records that are related with a set of
     * diagnosis. Usually this method is invoked when some action is performed
     * on the diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_intervs_status_pause
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_st_pause_for_diags
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_diag_ids       IN table_number,
        i_suspend_reason IN icnp_epis_intervention.id_suspend_reason%TYPE,
        i_suspend_notes  IN icnp_epis_intervention.suspend_notes%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_st_pause_for_diags';
        l_status     table_varchar;
        l_interv_ids table_number;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the interventions associated with the diagnosis that must be updated
        l_status     := table_varchar(pk_icnp_constant.g_epis_interv_status_requested,
                                      pk_icnp_constant.g_epis_interv_status_ongoing);
        l_interv_ids := get_intervs_gen_for_diags(i_diag_ids => i_diag_ids, i_status => l_status);
    
        -- Pause the interventions associated with the diagnosis
        set_intervs_status_pause(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_interv_ids     => l_interv_ids,
                                 i_suspend_reason => i_suspend_reason,
                                 i_suspend_notes  => i_suspend_notes,
                                 i_sysdate_tstz   => i_sysdate_tstz);
    
    END set_interv_st_pause_for_diags;

    /**
     * Resumes all the intervention records that are related with a set of
     * diagnosis. Usually this method is invoked when some action is performed
     * on the diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_intervs_status_resume
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_st_resume_for_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diag_ids     IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_st_resume_for_diags';
        l_status     table_varchar;
        l_interv_ids table_number;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the interventions associated with the diagnosis that must be updated
        l_status     := table_varchar(pk_icnp_constant.g_epis_interv_status_suspended);
        l_interv_ids := get_intervs_gen_for_diags(i_diag_ids => i_diag_ids, i_status => l_status);
    
        -- Resume the interventions associated with the diagnosis
        set_intervs_status_resume(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_interv_ids   => l_interv_ids,
                                  i_sysdate_tstz => i_sysdate_tstz);
    
    END set_interv_st_resume_for_diags;

    /**
     * Cancels all the intervention records that are related with a set of
     * diagnosis. Usually this method is invoked when some action is performed
     * on the diagnosis.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_diag_ids The set of diagnosis identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_intervs_status_cancel
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_interv_st_cancel_for_diags
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diag_ids      IN table_number,
        i_cancel_reason IN icnp_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_epis_intervention.cancel_notes%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_interv_st_cancel_for_diags';
        l_status     table_varchar;
        l_interv_ids table_number;
    
        l_exist              NUMBER;
        l_interv_rowids_coll table_varchar;
        l_error              t_error_out;
        l_flg_status         icnp_epis_diag_interv.flg_status%TYPE;
    
        l_interv_row_coll ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc;
        l_iedi_row_coll   icnp_epis_diag_interv%ROWTYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_diag_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_diag_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the interventions associated with the diagnosis that must be updated
        l_status     := table_varchar(pk_icnp_constant.g_epis_interv_status_requested,
                                      pk_icnp_constant.g_epis_interv_status_ongoing,
                                      pk_icnp_constant.g_epis_interv_status_suspended);
        l_interv_ids := get_intervs_gen_for_diags(i_diag_ids => i_diag_ids, i_status => l_status);
    
        -- Cancel the interventions associated with the diagnosis  
        FOR i IN 1 .. l_interv_ids.count
        LOOP
            BEGIN
                SELECT 1
                  INTO l_exist
                  FROM icnp_suggest_interv isi
                 WHERE isi.id_icnp_epis_interv = l_interv_ids(i)
                   AND isi.flg_status = pk_icnp_constant.g_sug_interv_status_accepted;
            
                ts_icnp_epis_diag_interv.upd(flg_status_in      => pk_icnp_constant.g_iedi_st_inactive,
                                             dt_inactivation_in => i_sysdate_tstz,
                                             id_prof_assoc_in   => i_prof.id,
                                             where_in           => ' id_icnp_epis_interv = ' || l_interv_ids(i) ||
                                                                   ' AND flg_status = ''' ||
                                                                   pk_icnp_constant.g_iedi_st_active || '''',
                                             rows_out           => l_interv_rowids_coll);
            EXCEPTION
                WHEN no_data_found THEN
                    BEGIN
                        SELECT 1
                          INTO l_exist
                          FROM icnp_epis_diag_interv iedi
                         WHERE iedi.id_icnp_epis_interv = l_interv_ids(i)
                           AND iedi.id_icnp_epis_diag NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                               *
                                                                FROM TABLE(i_diag_ids) t)
                           AND iedi.flg_status = pk_icnp_constant.g_iedi_st_active;
                    
                        ts_icnp_epis_diag_interv.upd(flg_status_in      => pk_icnp_constant.g_iedi_st_inactive,
                                                     dt_inactivation_in => i_sysdate_tstz,
                                                     id_prof_assoc_in   => i_prof.id,
                                                     where_in           => ' id_icnp_epis_interv = ' || l_interv_ids(i) ||
                                                                           ' AND id_icnp_epis_diag IN (' ||
                                                                           pk_utils.concat_table(i_diag_ids, ', ') || ')' ||
                                                                           ' AND flg_status = ''' ||
                                                                           pk_icnp_constant.g_iedi_st_active || '''',
                                                     rows_out           => l_interv_rowids_coll);
                    EXCEPTION
                        WHEN no_data_found THEN
                            -- Cancel the intervention
                            set_intervs_status_cancel(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_interv_ids    => table_number(l_interv_ids(i)),
                                                      i_cancel_reason => i_cancel_reason,
                                                      i_cancel_notes  => i_cancel_notes,
                                                      i_sysdate_tstz  => i_sysdate_tstz);
                    END;
            END;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ICNP_EPIS_DIAG_INTERV',
                                          i_rowids     => l_interv_rowids_coll,
                                          o_error      => l_error);
        END LOOP;
    
        IF l_interv_rowids_coll IS NOT NULL
        THEN
            l_interv_row_coll := get_iedi_rows(i_interv_ids => l_interv_ids);
            FOR x IN 1 .. l_interv_row_coll.count
            LOOP
                l_iedi_row_coll := l_interv_row_coll(x);
            
                ts_icnp_epis_dg_int_hist.ins(id_icnp_epis_dg_int_hist_in => ts_icnp_epis_dg_int_hist.next_key,
                                             id_icnp_epis_diag_interv_in => l_iedi_row_coll.id_icnp_epis_diag_interv,
                                             id_icnp_epis_diag_in        => l_iedi_row_coll.id_icnp_epis_diag,
                                             id_icnp_epis_interv_in      => l_iedi_row_coll.id_icnp_epis_interv,
                                             flg_status_in               => 'I',
                                             dt_inactivation_in          => i_sysdate_tstz,
                                             dt_hist_in                  => current_timestamp,
                                             flg_iud_in                  => 'U', --UPDATE
                                             id_prof_assoc_in            => i_prof.id,
                                             rows_out                    => l_interv_rowids_coll);
            
            END LOOP;
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ICNP_EPIS_DG_INT_HIST',
                                          i_rowids     => l_interv_rowids_coll,
                                          o_error      => l_error);
        
        END IF;
    END set_interv_st_cancel_for_diags;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE INTERV STATUS AND DT NEXT]
    --------------------------------------------------------------------------------

    /**
     * Updates the status and the next execution date of an intervention record 
     * (icnp_epis_intervention row).
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention that we want to 
     *                         update.
     * @param i_action An action performed by the user that caused the status change.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_interv_stat_and_dtnext
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_action         IN action.code_action%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_interv_stat_and_dtnext';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Updates the status and the next execution date
        update_intervs_stat_and_dtnext(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_interv_ids   => table_number(i_epis_interv_id),
                                       i_action       => i_action,
                                       i_sysdate_tstz => i_sysdate_tstz);
    
    END update_interv_stat_and_dtnext;

    /**
     * Updates the status and the next execution date of set of intervention records
     * (icnp_epis_intervention rows).
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of identifiers of the interventions that we want 
     *                     to update.
     * @param i_action An action performed by the user that caused the status change.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_intervs_stat_and_dtnext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_action       IN action.code_action%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        -----
        -- Constants
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_intervs_stat_and_dtnext';
        -----
        -- Variables related with the icnp_epis_intervention table
        l_interv_row         icnp_epis_intervention%ROWTYPE;
        l_interv_row_coll    ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_cols               table_varchar;
        l_interv_rowids_coll table_varchar;
        l_interv_status_old  icnp_epis_intervention.flg_status%TYPE;
        l_interv_status_new  icnp_epis_intervention.flg_status%TYPE;
        l_interv_dt_next_old icnp_epis_intervention.dt_next_tstz%TYPE;
        l_interv_dt_next_new icnp_epis_intervention.dt_next_tstz%TYPE;
        -----
        -- Collection of icnp_epis_intervention rows that we need to create the history records
        l_interv_hist_row      icnp_epis_intervention%ROWTYPE;
        l_interv_hist_row_coll ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        -- Identifiers of the created history records
        l_interv_hist table_number;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_interv_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the intervention rows of all the ids
        l_interv_row_coll := get_interv_rows(i_interv_ids => i_interv_ids);
    
        -- Make the necessary changes to each intervention record in the collection
        FOR i IN l_interv_row_coll.first .. l_interv_row_coll.last
        LOOP
            l_interv_row         := l_interv_row_coll(i);
            l_interv_hist_row    := l_interv_row;
            l_interv_status_old  := l_interv_row.flg_status;
            l_interv_dt_next_old := l_interv_row.dt_next_tstz;
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_int_row_statdtnext_cols(i_prof         => i_prof,
                                                     i_action       => i_action,
                                                     i_sysdate_tstz => i_sysdate_tstz,
                                                     io_interv_row  => l_interv_row);
        
            -- History records should only be created when the status is changed
            l_interv_status_new  := l_interv_row.flg_status;
            l_interv_dt_next_new := l_interv_row.dt_next_tstz;
            log_debug('l_interv_status_old: ' || l_interv_status_old || ', l_interv_status_new: ' ||
                      l_interv_status_new,
                      c_func_name);
            IF l_interv_status_old <> l_interv_status_new
               OR l_interv_dt_next_old <> l_interv_dt_next_new
            THEN
                l_interv_hist_row_coll(l_interv_hist_row_coll.count) := l_interv_hist_row;
            END IF;
        
            l_interv_row_coll(i) := l_interv_row;
        END LOOP;
    
        IF NOT pk_icnp_util.is_table_empty(l_interv_hist_row_coll)
        THEN
        
            -- Creates history records for all the interventions whose status changed
            create_interv_hist(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_interv_coll  => l_interv_hist_row_coll,
                               i_sysdate_tstz => i_sysdate_tstz,
                               o_interv_hist  => l_interv_hist);
        
            -- Persist the data into the database
            update_interv_rows(i_lang               => i_lang,
                               i_prof               => i_prof,
                               i_interv_row_coll    => l_interv_row_coll,
                               i_cols               => l_cols,
                               o_interv_rowids_coll => l_interv_rowids_coll);
        
        END IF;
    
    END update_intervs_stat_and_dtnext;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE AND GET INTERV EXEC]
    --------------------------------------------------------------------------------

    /**
     * This method receives a collection of intervention identifiers. For each
     * intervention identifier, gets the next execution id and adds it to a collection
     * for return. In the end we have a collection with the next execution to be 
     * performed for each intervention.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids Collection with the intervention identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return A collection of records with the information needed to correctly execute 
     *         several interventions.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 27/Jul/2011 (v2.6.1)
    */
    FUNCTION create_get_intvs_nextexec_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN pk_icnp_type.t_exec_interv_coll IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_get_intvs_nextexec_data';
        l_interv_row_coll  ts_icnp_epis_intervention.icnp_epis_intervention_tc;
        l_interv_row       icnp_epis_intervention%ROWTYPE;
        l_exec_row         icnp_interv_plan%ROWTYPE;
        l_exec_interv_coll pk_icnp_type.t_exec_interv_coll := pk_icnp_type.t_exec_interv_coll();
        l_exec_interv_rec  pk_icnp_type.t_exec_interv_rec;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_interv_ids is already being checked in pk_icnp_fo_api_db. 
         * When invoked from this package there is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            RETURN l_exec_interv_coll;
        END IF;
    
        -- Gets the intervention rows of all the intervention identifiers given as input 
        -- parameter
        l_interv_row_coll := get_interv_rows(i_interv_ids => i_interv_ids);
    
        -- Get the next execution for each intervention in the collection
        FOR i IN l_interv_row_coll.first .. l_interv_row_coll.last
        LOOP
            l_interv_row := l_interv_row_coll(i);
        
            -- If the frequency type is "no schedule" we really don't have a next execution
            -- planned; on those cases we need to create the execution
            IF l_interv_row.flg_type = pk_icnp_constant.g_epis_interv_type_no_schedule
               OR (l_interv_row.flg_type = pk_icnp_constant.g_epis_interv_type_once AND
               l_interv_row.flg_time = pk_icnp_constant.g_epis_interv_time_before_epis)
            THEN
                -- FIXME: To be faster, we could create an overloaded method that returns the 
                -- created execution 
                pk_icnp_exec.create_execution(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_epis_interv_id    => l_interv_row.id_icnp_epis_interv,
                                              i_dt_plan_tstz      => NULL,
                                              i_exec_number       => NULL,
                                              i_order_recurr_plan => l_interv_row.id_order_recurr_plan,
                                              i_sysdate_tstz      => i_sysdate_tstz);
            END IF;
        
            -- Get the next execution identifier and add it to the collection that will be returned
            l_exec_row := get_interv_next_exec_row(i_epis_interv_id => l_interv_row.id_icnp_epis_interv);
        
            -- Populate the record with the information needed to correctly execute and intervention
            l_exec_interv_rec.id_icnp_interv_plan  := l_exec_row.id_icnp_interv_plan;
            l_exec_interv_rec.id_icnp_epis_interv  := l_exec_row.id_icnp_epis_interv;
            l_exec_interv_rec.id_order_recurr_plan := l_interv_row.id_order_recurr_plan;
            IF (l_interv_row.flg_type = pk_icnp_constant.g_epis_interv_type_no_schedule OR
               (l_interv_row.flg_type = pk_icnp_constant.g_epis_interv_type_once AND
               l_interv_row.flg_time = pk_icnp_constant.g_epis_interv_time_before_epis))
            THEN
                l_exec_interv_rec.id_order_recurr_plan := NULL;
            ELSE
                l_exec_interv_rec.id_order_recurr_plan := l_interv_row.id_order_recurr_plan;
            END IF;
            l_exec_interv_rec.exec_number := l_exec_row.exec_number;
        
            -- Add the record to the collection
            l_exec_interv_coll.extend;
            l_exec_interv_coll(l_exec_interv_coll.count) := l_exec_interv_rec;
        END LOOP;
    
        RETURN l_exec_interv_coll;
    
    END create_get_intvs_nextexec_data;

    /**
     * Gets the next execution identifier for the intervention id given as input parameter.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The intervention identifier.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @return A record with the information needed to correctly execute an intervention.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 27/Jul/2011 (v2.6.1)
    */
    FUNCTION create_get_intv_nextexec_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN pk_icnp_type.t_exec_interv_rec IS
        l_exec_interv_coll pk_icnp_type.t_exec_interv_coll;
    
    BEGIN
        l_exec_interv_coll := create_get_intvs_nextexec_data(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_interv_ids   => table_number(i_epis_interv_id),
                                                             i_sysdate_tstz => i_sysdate_tstz);
        RETURN l_exec_interv_coll(1);
    
    END create_get_intv_nextexec_data;

    /**
     * Gets the intervention data (icnp_epis_diag_interv row) of all the intervention
     * identifiers given as input parameter.
     *
     * @param i_interv_ids Collection with the intervention identifiers.
     * 
     * @return Collection with the intervention data (icnp_epis_diag_interv row).
     * 
     * @author Nuno Neves
     * @version 1.0
     * @since 27-02-2012
    */
    FUNCTION get_iedi_rows(i_interv_ids IN table_number) RETURN ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'GET_IEDI_ROWS';
        l_interv_row_coll ts_icnp_epis_diag_interv.icnp_epis_diag_interv_tc;
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT iedi.*
          BULK COLLECT
          INTO l_interv_row_coll
          FROM icnp_epis_diag_interv iedi
         WHERE iedi.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             t.column_value id_icnp_epis_interv
                                              FROM TABLE(i_interv_ids) t);
    
        RETURN l_interv_row_coll;
    
    END get_iedi_rows;

    FUNCTION get_icnp_interv_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_icnp_epis_interv   IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
    
        l_description            CLOB;
        l_desc_icnp_intervention CLOB;
        l_instructions           CLOB;
        l_notes                  CLOB;
        l_status                 sys_domain.desc_val%TYPE;
        l_notes_msg              VARCHAR2(1000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'PN_M030');
        l_flg_prn                sys_message.desc_message%TYPE;
        l_date_take              icnp_interv_plan.dt_take_tstz%TYPE;
    BEGIN
    
        SELECT pk_icnp.desc_composition(i_lang, iei.id_composition) desc_intervention,
           --    pk_icnp_fo.get_interv_instructions(i_lang, i_prof, iei.id_icnp_epis_interv),
               pk_icnp_fo.get_instructions(i_lang,
                                           i_prof,
                                           iei.flg_type,
                                           iei.flg_time,
                                           iei.dt_begin_tstz,
                                           iei.id_order_recurr_plan,
                                           pk_icnp_constant.g_inst_format_opt_start_date ||
                                           pk_icnp_constant.g_inst_format_opt_frequency) , 
                                           notes,
               pk_sysdomain.get_domain('ICNP_EPIS_INTERVENTION.FLG_STATUS', iei.flg_status, i_lang),
               flg_prn
          INTO l_desc_icnp_intervention, l_instructions, l_notes, l_status, l_flg_prn
          FROM icnp_epis_intervention iei
         WHERE iei.id_icnp_epis_interv = i_id_icnp_epis_interv;
        BEGIN
            SELECT dt_take_tstz
              INTO l_date_take
              FROM (SELECT iip.dt_take_tstz, row_number() over(ORDER BY iip.dt_take_tstz DESC) rn
                      FROM icnp_interv_plan iip
                      JOIN icnp_epis_intervention i
                        ON i.id_icnp_epis_interv = iip.id_icnp_epis_interv
                     WHERE iip.id_icnp_epis_interv = i_id_icnp_epis_interv
                       AND iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_executed))
             WHERE rn = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_date_take := NULL;
        END;
        IF (i_description_condition IS NOT NULL)
        THEN
            --l_tbl_desc_condition := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            --   FOR i IN 1 .. l_tbl_desc_condition.last
            --  LOOP
            --null;
            --    END LOOP;
            NULL;
        ELSE
            IF l_desc_icnp_intervention IS NOT NULL
            THEN
                l_description := l_desc_icnp_intervention;
                IF l_flg_prn = pk_alert_constant.g_yes
                THEN
                    l_description := l_description || ' ' ||
                                     pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'CIPE_M007');
                END IF;
            
                IF l_instructions IS NOT NULL
                THEN
                    l_description := l_description || pk_prog_notes_constants.g_flg_sep || l_instructions;
                END IF;
            
                IF l_status IS NOT NULL
                THEN
                    l_description := l_description || pk_prog_notes_constants.g_flg_sep || l_status;
                END IF;
            
                IF l_notes IS NOT NULL
                THEN
                    l_description := l_description || pk_prog_notes_constants.g_flg_sep || l_status;
                END IF;
                IF l_date_take IS NOT NULL
                THEN
                    l_description := l_description || pk_prog_notes_constants.g_flg_sep ||
                                     pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'CIPE_T151') ||
                                     pk_prog_notes_constants.g_colon ||
                                     pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                        l_date_take,
                                                                        i_prof.institution,
                                                                        i_prof.software);
                END IF;
                l_description := l_description || pk_prog_notes_constants.g_period;
            ELSE
                l_description := NULL;
            END IF;
        END IF;
    
        RETURN l_description;
        --EXCEPTION WHEN OTHERS THEN RETURN NULL;
    END get_icnp_interv_desc;
BEGIN
    -- Executes all the instructions needed to correctly initialize the package
    initialize();

END pk_icnp_interv;
/
