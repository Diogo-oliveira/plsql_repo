/*-- Last Change Revision: $Rev: 2027219 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp_exec IS

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
     * @since 03/Jun/2011
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
     * Creates a collection with intervention plan identifiers from the collection 
     * that has all the data needed to correctly execute an intervention.
     * 
     * @param i_exec_interv_coll The collection with all the data needed to correctly 
     *                           execute an intervention.
     * 
     * @return The collection with intervention plan identifiers.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 08/Sep/2011
    */
    FUNCTION get_exec_ids(i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll) RETURN table_number IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_exec_ids';
        l_exec_ids table_number := table_number();
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Creates the new collection with the intervention plan identifiers
        FOR i IN i_exec_interv_coll.first .. i_exec_interv_coll.last
        LOOP
            l_exec_ids.extend;
            l_exec_ids(l_exec_ids.count) := i_exec_interv_coll(i).id_icnp_interv_plan;
        END LOOP;
    
        RETURN l_exec_ids;
    END;

    --------------------------------------------------------------------------------
    -- METHODS [RECURRENCE]
    --------------------------------------------------------------------------------

    /**
     * Recalculates the plan of a given set of interventions by ajusting the planned 
     * date and the execution number of all of them that weren't yet executed.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_interv_coll The collection with all the data needed to correctly 
     *                           execute a set of interventions.
     * @param i_dt_take_tstz Timestamp that identifies the moment in time when the 
     *                       planned execution was effectively executed.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 08/Sep/2011
    */
    PROCEDURE recalculate_plan
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll,
        i_dt_take_tstz     IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_sysdate_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'recalculate_plan';
        l_plan_calc_mode  sys_config.value%TYPE;
        l_exec_interv_rec pk_icnp_type.t_exec_interv_rec;
        l_exec_to_process t_tbl_order_recurr_plan_sts;
        l_error           t_error_out;
        -- The updated plan as sent by the recurrence mechanism (without modifications)
        l_exec_plan_all t_tbl_order_recurr_plan;
        -- The updated plan, but with only the executions with the status requested
        l_exec_plan_stat_req t_tbl_order_recurr_plan;
    
        l_exec_num_recurr   icnp_interv_plan.exec_number%TYPE;
        l_exec_num_cipe     icnp_interv_plan.exec_number%TYPE;
        l_count_orp_interv  NUMBER;
        l_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE;
        l_upd_rowids_coll   table_varchar;
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- We only need to make changes to the plan when the calc mode is based
        -- in the execution date
        l_plan_calc_mode := pk_sysconfig.get_config(i_code_cf => pk_icnp_constant.g_config_plan_calc_mode,
                                                    i_prof    => i_prof);
        IF l_plan_calc_mode = pk_icnp_constant.g_plan_calc_mode_planned_date
        THEN
            RETURN;
        END IF;
    
        -- For each intervention, check if there is the need to create the next execution
        FOR i IN i_exec_interv_coll.first .. i_exec_interv_coll.last
        LOOP
            l_exec_interv_rec := i_exec_interv_coll(i);
        
            BEGIN
                SELECT COUNT(1)
                  INTO l_exec_num_recurr
                  FROM icnp_interv_plan i
                 WHERE i.id_icnp_epis_interv = l_exec_interv_rec.id_icnp_epis_interv
                   AND i.id_order_recurr_plan = l_exec_interv_rec.id_order_recurr_plan
                   AND i.flg_status IN
                       (pk_icnp_constant.g_interv_plan_status_cancelled, pk_icnp_constant.g_interv_plan_status_executed);
            EXCEPTION
                WHEN no_data_found THEN
                    l_exec_num_recurr := 0;
            END;
        
            BEGIN
                SELECT COUNT(1)
                  INTO l_exec_num_cipe
                  FROM icnp_interv_plan i
                 WHERE i.id_icnp_epis_interv = l_exec_interv_rec.id_icnp_epis_interv
                   AND i.id_order_recurr_plan IS NOT NULL
                   AND i.id_order_recurr_plan != l_exec_interv_rec.id_order_recurr_plan
                   AND i.flg_status IN
                       (pk_icnp_constant.g_interv_plan_status_cancelled, pk_icnp_constant.g_interv_plan_status_executed);
            EXCEPTION
                WHEN no_data_found THEN
                    l_exec_num_cipe := 0;
            END;
        
            -- We only need to make changes to the plan when there is a recurrence plan 
            -- associated with the intervention
            IF l_exec_interv_rec.id_order_recurr_plan IS NOT NULL
            THEN
                BEGIN
                    SELECT COUNT(*)
                      INTO l_count_orp_interv
                      FROM (SELECT iip.id_icnp_epis_interv
                              FROM icnp_interv_plan iip
                             WHERE iip.id_order_recurr_plan = l_exec_interv_rec.id_order_recurr_plan
                             GROUP BY iip.id_icnp_epis_interv);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_count_orp_interv := 0;
                END;
            
                IF l_count_orp_interv > 1
                THEN
                    -- Get the updated plan
                    IF NOT pk_order_recurrence_api_db.update_execution_plan(i_lang                => i_lang,
                                                                            i_prof                => i_prof,
                                                                            i_order_recurr_plan   => l_exec_interv_rec.id_order_recurr_plan,
                                                                            i_execution_number    => l_exec_num_recurr,
                                                                            i_execution_timestamp => i_dt_take_tstz,
                                                                            i_flg_need_new_plan   => pk_alert_constant.g_yes,
                                                                            o_order_plan_exec     => l_exec_plan_all,
                                                                            o_order_recurr_plan   => l_order_recurr_plan,
                                                                            o_error               => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.update_execution_plan',
                                                            l_error);
                    END IF;
                ELSE
                    -- Get the updated plan
                    IF NOT pk_order_recurrence_api_db.update_execution_plan(i_lang                => i_lang,
                                                                            i_prof                => i_prof,
                                                                            i_order_recurr_plan   => l_exec_interv_rec.id_order_recurr_plan,
                                                                            i_execution_number    => l_exec_num_recurr,
                                                                            i_execution_timestamp => i_dt_take_tstz,
                                                                            i_flg_need_new_plan   => pk_alert_constant.g_no,
                                                                            o_order_plan_exec     => l_exec_plan_all,
                                                                            o_order_recurr_plan   => l_order_recurr_plan,
                                                                            o_error               => l_error)
                    THEN
                        pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.update_execution_plan',
                                                            l_error);
                    END IF;
                END IF;
            
                -- Filter the updated plan (sent by the recurrence mechanism) to include
                -- only the interventions with the status requested
                -- We don't want to update the planned date for executions that are already
                -- executed or cancelled
                SELECT t_rec_order_recurr_plan(ope.id_order_recurrence_plan, --l_order_recurr_plan,
                                               ope.exec_number + l_exec_num_cipe,
                                               ope.exec_timestamp)
                  BULK COLLECT
                  INTO l_exec_plan_stat_req
                  FROM TABLE(l_exec_plan_all) ope;
            
                ts_icnp_epis_intervention.upd(id_icnp_epis_interv_in  => l_exec_interv_rec.id_icnp_epis_interv,
                                              id_order_recurr_plan_in => l_order_recurr_plan,
                                              rows_out                => l_upd_rowids_coll);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_EPIS_INTERVENTION',
                                              i_rowids     => l_upd_rowids_coll,
                                              o_error      => l_error);
            
                -- Delete all the executions with the status requested; they will be recreated
                ts_icnp_interv_plan.del_by(where_clause_in => 'id_icnp_epis_interv = ' ||
                                                              l_exec_interv_rec.id_icnp_epis_interv ||
                                                              ' AND flg_status = ''' ||
                                                              pk_icnp_constant.g_interv_plan_status_requested || '''');
            
                t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_INTERV_PLAN',
                                              i_rowids     => l_upd_rowids_coll,
                                              o_error      => l_error);
            
                -- Recreate the executions with the new planned date
                create_executions(i_lang            => i_lang,
                                  i_prof            => i_prof,
                                  i_exec_tab        => l_exec_plan_stat_req,
                                  i_sysdate_tstz    => i_sysdate_tstz,
                                  o_exec_to_process => l_exec_to_process);
            
                ts_icnp_interv_plan.upd(id_order_recurr_plan_in => l_order_recurr_plan,
                                        dt_last_update_in       => i_sysdate_tstz,
                                        where_in                => 'id_icnp_epis_interv = ' ||
                                                                   l_exec_interv_rec.id_icnp_epis_interv ||
                                                                   ' AND id_order_recurr_plan = ' ||
                                                                   l_exec_interv_rec.id_order_recurr_plan ||
                                                                   ' AND flg_status = ''' ||
                                                                   pk_icnp_constant.g_interv_plan_status_requested || '''',
                                        rows_out                => l_upd_rowids_coll);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ICNP_INTERV_PLAN',
                                              i_rowids     => l_upd_rowids_coll,
                                              o_error      => l_error);
            END IF;
        END LOOP;
    
    END recalculate_plan;

    /**
     * Creates a next execution in the plan table when there are more executions to be 
     * done, but they are no yet in the plan table. The invocation of the method that
     * effectively creates the execution is made by the recurrence mechanism. This
     * method is the one that has the logic, but several others exist as wrappers.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The intervention identifier that will be checked to see
     *                         if there is the need to create the next execution.
     * @param i_order_recurr_plan_id The recurrence plan identifier of the intervention.
     *
     * @see create_next_exec_by_intv_coll
     * @see create_next_exec_by_intv_rec
     * @see create_next_exec_by_intv_id
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 09/Sep/2011 (v2.6.1)
    */
    PROCEDURE create_next_exec
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis_interv_id       IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        i_order_recurr_plan_id IN icnp_epis_intervention.id_order_recurr_plan%TYPE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_next_exec';
        l_planned_execs_count PLS_INTEGER;
        l_error               t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Gets the number of planned executions
        l_planned_execs_count := pk_icnp_interv.get_interv_planned_execs_count(i_epis_interv_id => i_epis_interv_id);
    
        -- Creates a next execution in the plan table (if needed)
        log_debug('calling set_active_executions / i_epis_interv_id: ' || i_epis_interv_id ||
                  ', i_order_recurr_plan_id: ' || i_order_recurr_plan_id || ', l_planned_execs_count: ' ||
                  l_planned_execs_count,
                  c_func_name);
        IF NOT pk_order_recurrence_api_db.set_active_executions(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_order_recurr_plan => i_order_recurr_plan_id,
                                                                i_active_executions => l_planned_execs_count,
                                                                o_error             => l_error)
        THEN
            pk_icnp_util.raise_unexpected_error('pk_order_recurrence_api_db.set_active_executions', l_error);
        END IF;
    
    END create_next_exec;

    /**
     * Creates a next execution in the plan table when there are more executions to be 
     * done, but they are no yet in the plan table. The invocation of the method that
     * effectively creates the execution is made by the recurrence mechanism.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_interv_coll The collection of executed interventions. For each we
     *                           will check if there is the need to create the next execution.
     *
     * @see create_next_exec
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 9/Sep/2011 (v2.6.1)
    */
    PROCEDURE create_next_exec_by_intv_coll
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_next_exec_by_intv_coll';
        l_exec_interv_rec pk_icnp_type.t_exec_interv_rec;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- For each intervention, check if there is the need to create the next execution
        FOR i IN i_exec_interv_coll.first .. i_exec_interv_coll.last
        LOOP
            l_exec_interv_rec := i_exec_interv_coll(i);
        
            -- The method should only be invoked when there is a recurrence plan associated 
            -- with the intervention
            IF l_exec_interv_rec.id_order_recurr_plan IS NOT NULL
            THEN
                create_next_exec(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_epis_interv_id       => l_exec_interv_rec.id_icnp_epis_interv,
                                 i_order_recurr_plan_id => l_exec_interv_rec.id_order_recurr_plan);
            END IF;
        END LOOP;
    
    END create_next_exec_by_intv_coll;

    /**
     * Creates a next execution in the plan table when there are more executions to be 
     * done, but they are no yet in the plan table. The invocation of the method that
     * effectively creates the execution is made by the recurrence mechanism.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_interv_rec The data of the executed intervention. The intervention
     *                          is going to be checked in order to determine if there 
     *                          is the need to create the next execution.
     *
     * @see create_next_exec
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 09/Sep/2011 (v2.6.1)
    */
    PROCEDURE create_next_exec_by_intv_rec
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_interv_rec IN pk_icnp_type.t_exec_interv_rec
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_next_exec_by_intv_rec';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        create_next_exec_by_intv_coll(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_exec_interv_coll => pk_icnp_type.t_exec_interv_coll(i_exec_interv_rec));
    
    END create_next_exec_by_intv_rec;

    /**
     * Creates a next execution in the plan table when there are more executions to be 
     * done, but they are no yet in the plan table. The invocation of the method that
     * effectively creates the execution is made by the recurrence mechanism.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The intervention identifier that will be checked to see
     *                         if there is the need to create the next execution.
     * 
     * @see create_next_exec
     *
     * @author Luis Oliveira
     * @version 1.0
     * @since 09/Sep/2011 (v2.6.1)
    */
    PROCEDURE create_next_exec_by_intv_id
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_interv_id IN icnp_epis_intervention.id_icnp_epis_interv%TYPE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_next_exec_by_intv_id';
        l_interv_row icnp_epis_intervention%ROWTYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Gets the intervention row for the given id
        l_interv_row := pk_icnp_interv.get_interv_row(i_epis_interv_id => i_epis_interv_id);
    
        -- Creates a next execution in the plan table (if needed)
        create_next_exec(i_lang                 => i_lang,
                         i_prof                 => i_prof,
                         i_epis_interv_id       => l_interv_row.id_icnp_epis_interv,
                         i_order_recurr_plan_id => l_interv_row.id_order_recurr_plan);
    
    END create_next_exec_by_intv_id;

    --------------------------------------------------------------------------------
    -- METHODS [GET EXEC ROW]
    --------------------------------------------------------------------------------

    /**
     * Gets the execution data (icnp_interv_plan row) of all the intervention
     * identifiers given as input parameter.
     *
     * @param i_exec_ids Collection with the execution identifiers.
     * 
     * @return Collection with the execution data (icnp_interv_plan row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION get_exec_rows(i_exec_ids IN table_number) RETURN ts_icnp_interv_plan.icnp_interv_plan_tc IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_exec_rows';
        l_exec_row_coll ts_icnp_interv_plan.icnp_interv_plan_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT iip.*
          BULK COLLECT
          INTO l_exec_row_coll
          FROM icnp_interv_plan iip
         WHERE iip.id_icnp_interv_plan IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            t.column_value id_icnp_interv_plan
                                             FROM TABLE(i_exec_ids) t);
    
        RETURN l_exec_row_coll;
    
    END get_exec_rows;

    /**
     * Gets the execution data (icnp_interv_plan row) of a given execution
     * identifier given as input parameter.
     *
     * @param i_interv_plan_id The execution identifier.
     * 
     * @return The intervention data (icnp_interv_plan row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION get_exec_row(i_interv_plan_id IN icnp_interv_plan.id_icnp_interv_plan%TYPE) RETURN icnp_interv_plan%ROWTYPE IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_exec_row';
        l_exec_row icnp_interv_plan%ROWTYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        SELECT iip.*
          INTO l_exec_row
          FROM icnp_interv_plan iip
         WHERE iip.id_icnp_interv_plan = i_interv_plan_id;
    
        RETURN l_exec_row;
    
    END get_exec_row;

    --------------------------------------------------------------------------------
    -- METHODS [CREATE]
    --------------------------------------------------------------------------------

    /**
     * Creates a new execution record (icnp_interv_plan row).
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_interv_id The identifier of the intervention that will be 
     *                         associated to the created execution.
     * @param i_dt_plan_tstz Planned date of the execution.
     * @param i_exec_number The order of the execution within the plan as specified by 
     *                      the recurrence mechanism.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_execution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_interv_id    IN icnp_interv_plan.id_icnp_epis_interv%TYPE,
        i_dt_plan_tstz      IN icnp_interv_plan.dt_plan_tstz%TYPE,
        i_exec_number       IN icnp_interv_plan.exec_number%TYPE,
        i_order_recurr_plan IN icnp_interv_plan.id_order_recurr_plan%TYPE,
        i_sysdate_tstz      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_execution';
        l_exec_rowids_coll table_varchar;
        l_error            t_error_out;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Persist the data into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_interv_plan.ins(id_icnp_interv_plan_in  => ts_icnp_interv_plan.next_key,
                                id_icnp_epis_interv_in  => i_epis_interv_id,
                                flg_status_in           => pk_icnp_constant.g_interv_plan_status_requested,
                                dt_plan_tstz_in         => i_dt_plan_tstz,
                                id_prof_created_in      => i_prof.id,
                                dt_created_in           => i_sysdate_tstz,
                                dt_last_update_in       => i_sysdate_tstz,
                                exec_number_in          => i_exec_number,
                                id_order_recurr_plan_in => i_order_recurr_plan,
                                rows_out                => l_exec_rowids_coll);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_INTERV_PLAN',
                                      i_rowids     => l_exec_rowids_coll,
                                      o_error      => l_error);
    
    END create_execution;

    /**
     * Creates a set of execution records (icnp_interv_plan rows). Each record of 
     * the collection is a icnp_interv_plan row already with the data that should
     * be persisted in the database. This method is prepared to be used by the 
     * recurrence mechanism.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_tab A collection with the execution order number and the planned 
     *                   date of execution.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_exec_to_process For each plan, indicates if there are more executions 
     *                          to be processed.
     * 
     * @value o_exec_to_process {*} 'Y' there are more executions to be processed {*} 'N' there are no more executions to be processed.
     *
     * @author Luis Oliveira
     * @version 1.1
     * @since 27/Jul/2011 (v2.6.1)
    */
    PROCEDURE create_executions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_exec_tab        IN t_tbl_order_recurr_plan,
        i_sysdate_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_exec_to_process OUT t_tbl_order_recurr_plan_sts
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'create_executions';
    
        -- returns outdated plans
        CURSOR c_icnp_interv_not(x_exec_tab IN t_tbl_order_recurr_plan) IS
            SELECT DISTINCT id_order_recurrence_plan
              FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                     t.id_order_recurrence_plan
                      FROM icnp_epis_intervention iei
                     RIGHT JOIN TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) t
                        ON (t.id_order_recurrence_plan = iei.id_order_recurr_plan)
                     WHERE iei.flg_status NOT IN -- plans that are associated to NOT active and NOT in execution interventions (are outdated) 
                           (pk_icnp_constant.g_epis_interv_status_requested,
                            pk_icnp_constant.g_epis_interv_status_ongoing)
                    UNION ALL
                    SELECT /*+ opt_estimate(table t rows=1)*/
                     t.id_order_recurrence_plan
                      FROM icnp_epis_intervention iei
                     RIGHT JOIN TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) t
                        ON (t.id_order_recurrence_plan = iei.id_order_recurr_plan)
                     WHERE iei.id_icnp_epis_interv IS NULL -- plans that are NOT associated to any intervention (they were changed and are outdated) 
                    );
    
        -- returns plans that has active or pending interventions
        CURSOR c_icnp_interv(x_exec_tab IN t_tbl_order_recurr_plan) IS
            SELECT /*+ opt_estimate(table t rows=1)*/
             iei.id_icnp_epis_interv,
             t.id_order_recurrence_plan,
             t.exec_number,
             t.exec_timestamp dt_plan_tstz,
             orp.id_order_recurr_option
              FROM icnp_epis_intervention iei
              JOIN TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) t
                ON (t.id_order_recurrence_plan = iei.id_order_recurr_plan)
              JOIN episode e
                ON e.id_episode = iei.id_episode
              JOIN visit v
                ON v.id_visit = e.id_visit
              LEFT JOIN order_recurr_plan orp
                ON orp.id_order_recurr_plan = iei.id_order_recurr_plan
            
             WHERE iei.flg_status IN
                   (pk_icnp_constant.g_epis_interv_status_requested, pk_icnp_constant.g_epis_interv_status_ongoing)
               AND v.flg_status = pk_visit.g_active;
    
        CURSOR c_state_visit(x_exec_tab IN t_tbl_order_recurr_plan) IS
            SELECT /*+ opt_estimate(table t rows=1) */
            DISTINCT v.flg_status
              FROM icnp_epis_intervention iei
              JOIN TABLE(CAST(x_exec_tab AS t_tbl_order_recurr_plan)) t
                ON (t.id_order_recurrence_plan = iei.id_order_recurr_plan)
              JOIN episode e
                ON e.id_episode = iei.id_episode
              JOIN visit v
                ON v.id_visit = e.id_visit
             WHERE iei.flg_status IN
                   (pk_icnp_constant.g_epis_interv_status_requested, pk_icnp_constant.g_epis_interv_status_ongoing)
               AND v.flg_status = pk_visit.g_active;
    
        TYPE t_icnp_interv IS TABLE OF c_icnp_interv%ROWTYPE;
        l_icnp_interv_tab t_icnp_interv;
    
        l_plans_oudated   table_number := table_number();
        l_plans_processed table_number := table_number();
    
        l_interv_row_coll  ts_icnp_interv_plan.icnp_interv_plan_tc;
        l_exec_rowids_coll table_varchar;
    
        l_interv_plan_row icnp_interv_plan%ROWTYPE;
        l_error           t_error_out;
    
        l_status_visit visit.flg_status%TYPE;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- check input
        IF i_exec_tab IS empty
        THEN
            RETURN;
        END IF;
    
        OPEN c_state_visit(i_exec_tab);
        FETCH c_state_visit
            INTO l_status_visit;
        CLOSE c_state_visit;
    
        IF l_status_visit != pk_visit.g_active
        THEN
            RETURN;
        END IF;
    
        -------
        -- Getting outdated plans
        log_debug('i_exec_tab.COUNT=' || i_exec_tab.count, c_func_name);
        OPEN c_icnp_interv_not(i_exec_tab);
        FETCH c_icnp_interv_not BULK COLLECT
            INTO l_plans_oudated;
        CLOSE c_icnp_interv_not;
    
        -------
        -- Getting all nurse_tea_reqs related to this order recurr plan
        OPEN c_icnp_interv(i_exec_tab);
        FETCH c_icnp_interv BULK COLLECT
            INTO l_icnp_interv_tab;
        CLOSE c_icnp_interv;
    
        <<req>>
        FOR req_idx IN 1 .. l_icnp_interv_tab.count
        LOOP
        
            -- for each req and each execution
            -- create executions
            log_debug('Call create_execution / i_id_nurse_tea_req=' || l_icnp_interv_tab(req_idx).id_icnp_epis_interv ||
                      ' i_num_order=' || l_icnp_interv_tab(req_idx).exec_number,
                      c_func_name);
        
            l_interv_plan_row.id_icnp_interv_plan  := ts_icnp_interv_plan.next_key;
            l_interv_plan_row.id_icnp_epis_interv  := l_icnp_interv_tab(req_idx).id_icnp_epis_interv;
            l_interv_plan_row.flg_status           := pk_icnp_constant.g_interv_plan_status_requested;
            l_interv_plan_row.dt_plan_tstz := CASE
                                                  WHEN l_icnp_interv_tab(req_idx).id_order_recurr_option = -2 THEN
                                                   NULL
                                                  ELSE
                                                   l_icnp_interv_tab(req_idx).dt_plan_tstz
                                              END;
            l_interv_plan_row.id_prof_created      := i_prof.id;
            l_interv_plan_row.dt_created           := i_sysdate_tstz;
            l_interv_plan_row.dt_last_update       := i_sysdate_tstz;
            l_interv_plan_row.exec_number          := l_icnp_interv_tab(req_idx).exec_number;
            l_interv_plan_row.id_order_recurr_plan := l_icnp_interv_tab(req_idx).id_order_recurrence_plan;
        
            l_interv_row_coll(req_idx) := l_interv_plan_row;
        
            -- plans processed
            log_debug('l_exec_to_process 2', c_func_name);
            l_plans_processed.extend;
            l_plans_processed(l_plans_processed.count) := l_icnp_interv_tab(req_idx).id_order_recurrence_plan;
        
        END LOOP req;
    
        -- Persist the data into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_interv_plan.ins(rows_in => l_interv_row_coll, rows_out => l_exec_rowids_coll);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_INTERV_PLAN',
                                      i_rowids     => l_exec_rowids_coll,
                                      o_error      => l_error);
    
        -- note:
        -- getting all plans processed and all plans outdated.
        -- if one plan is in both arrays, consider only plans processed and discard the outdated
        log_debug('l_plans_oudated.COUNT=' || l_plans_oudated.count || ' l_plans_processed.COUNT=' ||
                  l_plans_processed.count,
                  c_func_name);
        SELECT t_rec_order_recurr_plan_sts(column_value, flg_status)
          BULK COLLECT
          INTO o_exec_to_process
          FROM (
                -- plans processed
                SELECT column_value, pk_alert_constant.get_yes flg_status
                  FROM TABLE(CAST(l_plans_processed AS table_number))
                UNION
                -- plans outdated minus (plans processed intersect plans outdated)
                SELECT t.*, pk_alert_constant.get_no flg_status
                  FROM (SELECT *
                           FROM TABLE(CAST(l_plans_oudated AS table_number))
                         MINUS (SELECT *
                                 FROM TABLE(CAST(l_plans_oudated AS table_number))
                               INTERSECT
                               SELECT *
                                 FROM TABLE(CAST(l_plans_processed AS table_number)))) t);
    
    END create_executions;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE EXEC ROW]
    --------------------------------------------------------------------------------

    /**
     * Updates a set of execution records (icnp_interv_plan rows). Each record of the
     * collection is a icnp_interv_plan row already with the data that should be 
     * persisted in the database. The ALERT data governance mechanism demands that 
     * whenever an update is executed an event with the rows and columns updated is 
     * broadcasted. For that purpose, a set of column names (i_cols) should always be 
     * defined.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_row_coll Collection of icnp_interv_plan rows already with the
     *                        data that should be persisted in the database.
     * @param i_cols Set of column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_exec_rows
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exec_row_coll IN ts_icnp_interv_plan.icnp_interv_plan_tc,
        i_cols          IN table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_exec_rows';
        l_error            t_error_out;
        l_exec_rowids_coll table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_exec_row_coll)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the execution rows (i_exec_row_coll) given as input parameter is empty');
        END IF;
        IF pk_icnp_util.is_table_empty(i_cols)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the column names (i_cols) given as input parameter is empty');
        END IF;
    
        -- Persist the data into the database and brodcast the update through the data 
        -- governace mechanism
        ts_icnp_interv_plan.upd(col_in => i_exec_row_coll, ignore_if_null_in => FALSE, rows_out => l_exec_rowids_coll);
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ICNP_INTERV_PLAN',
                                      i_rowids       => l_exec_rowids_coll,
                                      o_error        => l_error,
                                      i_list_columns => i_cols);
    END update_exec_rows;

    /**
     * Updates a execution record (icnp_interv_plan row). The icnp_interv_plan 
     * row must already have the data that should be persisted in the database. The 
     * ALERT data governance mechanism demands that whenever an update is executed an 
     * event with the rows and columns updated is broadcasted. For that purpose, a set 
     * of column names (i_cols) should always be defined.
     *
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_row The icnp_interv_plan row already with the data that should
     *                   be persisted in the database.
     * @param i_cols Set of column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_exec_row
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exec_row IN icnp_interv_plan%ROWTYPE,
        i_cols     IN table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'update_exec_row';
        l_exec_row_coll ts_icnp_interv_plan.icnp_interv_plan_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Persist the data into the database
        l_exec_row_coll(1) := i_exec_row;
        update_exec_rows(i_lang => i_lang, i_prof => i_prof, i_exec_row_coll => l_exec_row_coll, i_cols => i_cols);
    
    END update_exec_row;

    --------------------------------------------------------------------------------
    -- METHODS [CHANGE ROW COLUMNS FOR UPDATE STATUS]
    --------------------------------------------------------------------------------

    /**
     * Updates all the necessary columns of an execution record (icnp_interv_plan row)
     * when only the status needs to be updated. A set with the column names that
     * were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_flg_status The new execution status.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_exec_row The icnp_interv_plan row whose columns will be updated.
     *                    This is an input/output argument because the execution
     *                    record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_exec_row_status_cols
    (
        i_flg_status   IN icnp_interv_plan.flg_status%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_exec_row    IN OUT NOCOPY icnp_interv_plan%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_exec_row_status_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the execution record
        io_exec_row.flg_status     := i_flg_status;
        io_exec_row.dt_last_update := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_exec_row_status_cols;

    /**
     * Updates all the necessary columns of an execution record (icnp_interv_plan row)
     * when the user cancels an execution. A set with the column names that
     * were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_exec_row The icnp_interv_plan row whose columns will be updated.
     *                    This is an input/output argument because the execution
     *                    record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_exec_row_cancel_cols
    (
        i_prof          IN profissional,
        i_cancel_reason IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_exec_row     IN OUT NOCOPY icnp_interv_plan%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_exec_row_cancel_cols';
        l_cols table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Update the columns of the execution record
        io_exec_row.flg_status       := pk_icnp_constant.g_interv_plan_status_cancelled;
        io_exec_row.id_prof_cancel   := i_prof.id;
        io_exec_row.notes_cancel     := i_cancel_notes;
        io_exec_row.dt_cancel_tstz   := i_sysdate_tstz;
        io_exec_row.id_cancel_reason := i_cancel_reason;
        io_exec_row.dt_last_update   := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS',
                                'ID_PROF_CANCEL',
                                'NOTES_CANCEL',
                                'DT_CANCEL_TSTZ',
                                'ID_CANCEL_REASON',
                                'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_exec_row_cancel_cols;

    /**
     * Updates all the necessary columns of an execution record (icnp_interv_plan row)
     * when the user executes a non-template execution. A set with the column names 
     * that were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_notes Notes with the details about the execution.
     * @param i_dt_take_tstz Timestamp that identifies the moment in time when the 
     *                       planned execution was effectively executed.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_exec_row The icnp_interv_plan row whose columns will be updated.
     *                    This is an input/output argument because the execution
     *                    record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_exec_row_exec_cols
    (
        i_prof         IN profissional,
        i_notes        IN icnp_interv_plan.notes%TYPE,
        i_dt_take_tstz IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_exec_row    IN OUT NOCOPY icnp_interv_plan%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_exec_row_execute_cols';
        l_dt_take_tstz icnp_interv_plan.dt_take_tstz%TYPE;
        l_cols         table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- When the date of the execution is not specified, the current timestamp is used
        l_dt_take_tstz := i_dt_take_tstz;
        IF i_dt_take_tstz IS NULL
        THEN
            l_dt_take_tstz := i_sysdate_tstz;
        END IF;
    
        -- Update the columns of the execution record
        io_exec_row.flg_status     := pk_icnp_constant.g_interv_plan_status_executed;
        io_exec_row.id_prof_take   := i_prof.id;
        io_exec_row.dt_take_tstz   := l_dt_take_tstz;
        io_exec_row.notes          := i_notes;
        io_exec_row.dt_last_update := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'ID_PROF_TAKE', 'DT_TAKE_TSTZ', 'NOTES', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_exec_row_exec_cols;

    /**
     * Updates all the necessary columns of an execution record (icnp_interv_plan row)
     * when the user executes a execution using a template. A set with the column names 
     * that were updated is returned to be used in the ALERT data governance mechanism.
     * 
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_epis_documentation_id Identifier of the template record where the execution
     *                                was documented.
     * @param i_dt_take_tstz Timestamp that identifies the moment in time when the 
     *                       planned execution was effectively executed.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param io_exec_row The icnp_interv_plan row whose columns will be updated.
     *                    This is an input/output argument because the execution
     *                    record can be updated too in other methods.
     * 
     * @return Set with the column names that were updated.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 5/Jun/2011 (v2.6.1)
    */
    FUNCTION change_exec_row_exec_doc_cols
    (
        i_prof                  IN profissional,
        i_epis_documentation_id IN icnp_interv_plan.id_epis_documentation%TYPE,
        i_dt_take_tstz          IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_sysdate_tstz          IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_exec_row             IN OUT NOCOPY icnp_interv_plan%ROWTYPE
    ) RETURN table_varchar IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'change_exec_row_execute_cols';
        l_dt_take_tstz icnp_interv_plan.dt_take_tstz%TYPE;
        l_cols         table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- When the date of the execution is not specified, the current timestamp is used
        l_dt_take_tstz := i_dt_take_tstz;
        IF i_dt_take_tstz IS NULL
        THEN
            l_dt_take_tstz := i_sysdate_tstz;
        END IF;
    
        -- Update the columns of the execution record
        io_exec_row.flg_status            := pk_icnp_constant.g_interv_plan_status_executed;
        io_exec_row.id_prof_take          := i_prof.id;
        io_exec_row.dt_take_tstz          := l_dt_take_tstz;
        io_exec_row.id_epis_documentation := i_epis_documentation_id;
        io_exec_row.dt_last_update        := i_sysdate_tstz;
    
        -- Populate the collection with the column names that were updated
        l_cols := table_varchar('FLG_STATUS', 'ID_PROF_TAKE', 'DT_TAKE_TSTZ', 'ID_EPIS_DOCUMENTATION', 'DT_LAST_UPDATE');
    
        RETURN l_cols;
    
    END change_exec_row_exec_doc_cols;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE EXEC STATUS]
    --------------------------------------------------------------------------------

    /**
     * Updates the status of a set of execution records (icnp_interv_plan rows).
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_ids The set of executions identifiers that we want to update.
     * @param i_flg_status The new execution status.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE update_execs_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exec_ids     IN table_number,
        i_flg_status   IN icnp_interv_plan.flg_status%TYPE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_execs_status';
        l_exec_row      icnp_interv_plan%ROWTYPE;
        l_exec_row_coll ts_icnp_interv_plan.icnp_interv_plan_tc;
        l_cols          table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_exec_ids is not being checked because it is only
         * used within this package. There is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_exec_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the execution rows of all the ids
        l_exec_row_coll := get_exec_rows(i_exec_ids => i_exec_ids);
    
        -- Make the necessary changes to each execution record in the collection
        FOR i IN l_exec_row_coll.first .. l_exec_row_coll.last
        LOOP
            l_exec_row := l_exec_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_exec_row_status_cols(i_flg_status   => i_flg_status,
                                                  i_sysdate_tstz => i_sysdate_tstz,
                                                  io_exec_row    => l_exec_row);
        
            l_exec_row_coll(i) := l_exec_row;
        END LOOP;
    
        -- Persist the data into the database
        update_exec_rows(i_lang => i_lang, i_prof => i_prof, i_exec_row_coll => l_exec_row_coll, i_cols => l_cols);
    
    END update_execs_status;

    /**
     * Makes the necessary updates to a set of execution records 
     * (icnp_interv_plan rows) when the user cancels executions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_ids The set of execution identifiers that we want to cancel.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_exec_row_coll Collection with the changed execution records (icnp_interv_plan rows).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_execs_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exec_ids      IN table_number,
        i_cancel_reason IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_exec_row_coll OUT ts_icnp_interv_plan.icnp_interv_plan_tc
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_execs_status_cancel';
        l_exec_row      icnp_interv_plan%ROWTYPE;
        l_exec_row_coll ts_icnp_interv_plan.icnp_interv_plan_tc;
        l_cols          table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        /* The input parameter i_exec_ids is not being checked because it is only
         * used within this package. There is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_exec_ids)
        THEN
            RETURN;
        END IF;
    
        -- Gets the execution rows of all the ids
        l_exec_row_coll := get_exec_rows(i_exec_ids => i_exec_ids);
    
        -- Make the necessary changes to each execution record in the collection
        FOR i IN l_exec_row_coll.first .. l_exec_row_coll.last
        LOOP
            l_exec_row := l_exec_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_exec_row_cancel_cols(i_prof          => i_prof,
                                                  i_cancel_reason => i_cancel_reason,
                                                  i_cancel_notes  => i_cancel_notes,
                                                  i_sysdate_tstz  => i_sysdate_tstz,
                                                  io_exec_row     => l_exec_row);
        
            l_exec_row_coll(i) := l_exec_row;
        
            -- Creates a next execution in the plan table (if needed)
            create_next_exec_by_intv_id(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_epis_interv_id => l_exec_row.id_icnp_epis_interv);
        END LOOP;
    
        -- Persist the data into the database
        update_exec_rows(i_lang => i_lang, i_prof => i_prof, i_exec_row_coll => l_exec_row_coll, i_cols => l_cols);
    
        -- Set the output parameters
        o_exec_row_coll := l_exec_row_coll;
    
    END set_execs_status_cancel;

    /**
     * @see set_execs_status_cancel 
    */
    PROCEDURE set_execs_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exec_ids      IN table_number,
        i_cancel_reason IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_execs_status_cancel';
        l_exec_row_coll ts_icnp_interv_plan.icnp_interv_plan_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Cancel the executions
        set_execs_status_cancel(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_exec_ids      => i_exec_ids,
                                i_cancel_reason => i_cancel_reason,
                                i_cancel_notes  => i_cancel_notes,
                                i_sysdate_tstz  => i_sysdate_tstz,
                                o_exec_row_coll => l_exec_row_coll);
    
    END set_execs_status_cancel;

    /**
     * Makes the necessary updates to an execution record (icnp_interv_plan row) when
     * the user cancels an execution.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_plan_id The execution identifier.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * @param o_exec_row The changed execution record (icnp_interv_plan row).
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_status_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_interv_plan_id IN icnp_interv_plan.id_icnp_interv_plan%TYPE,
        i_cancel_reason  IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_exec_row       OUT icnp_interv_plan%ROWTYPE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_status_cancel';
        l_exec_row_coll ts_icnp_interv_plan.icnp_interv_plan_tc;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Cancel the execution
        set_execs_status_cancel(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_exec_ids      => table_number(i_interv_plan_id),
                                i_cancel_reason => i_cancel_reason,
                                i_cancel_notes  => i_cancel_notes,
                                i_sysdate_tstz  => i_sysdate_tstz,
                                o_exec_row_coll => l_exec_row_coll);
    
        -- Set the output parameters
        o_exec_row := l_exec_row_coll(1);
    
    END set_exec_status_cancel;

    /**
     * @see set_exec_status_cancel 
    */
    PROCEDURE set_exec_status_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_interv_plan_id IN icnp_interv_plan.id_icnp_interv_plan%TYPE,
        i_cancel_reason  IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes   IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_status_cancel';
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Cancel the execution
        set_execs_status_cancel(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_exec_ids      => table_number(i_interv_plan_id),
                                i_cancel_reason => i_cancel_reason,
                                i_cancel_notes  => i_cancel_notes,
                                i_sysdate_tstz  => i_sysdate_tstz);
    
    END set_exec_status_cancel;

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows) 
     * when the user executes a non-template execution.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_interv_coll The collection with all the data needed to correctly 
     *                           execute an intervention.
     * @param i_notes Notes with the details about the execution.
     * @param i_dt_take_tstz Timestamp that identifies the moment in time when the 
     *                       planned execution was effectively executed.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_execs_status_execute
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_exec_interv_coll IN pk_icnp_type.t_exec_interv_coll,
        i_notes            IN icnp_interv_plan.notes%TYPE,
        i_dt_take_tstz     IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_sysdate_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_execs_status_execute';
        l_exec_ids      table_number;
        l_exec_row      icnp_interv_plan%ROWTYPE;
        l_exec_row_coll ts_icnp_interv_plan.icnp_interv_plan_tc;
        l_cols          table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(i_exec_ids:' || pk_icnp_util.to_string(i_exec_interv_coll) || ', i_notes:' ||
                  i_notes || ', i_dt_take_tstz:' || i_dt_take_tstz || ')',
                  c_func_name);
    
        /* The input parameter i_exec_ids is not being checked because it is not invoked
         * directly from the outside. There is no need to raise an exception.
        */
        IF pk_icnp_util.is_table_empty(i_exec_interv_coll)
        THEN
            RETURN;
        END IF;
    
        -- Gets the execution rows of all the ids
        l_exec_ids      := get_exec_ids(i_exec_interv_coll);
        l_exec_row_coll := get_exec_rows(i_exec_ids => l_exec_ids);
    
        -- Make the necessary changes to each execution record in the collection
        FOR i IN 1 .. l_exec_row_coll.count
        LOOP
            l_exec_row := l_exec_row_coll(i);
        
            /* :FIXME: there is no need to update l_cols on every iteration. A possible solution 
             * is to have a new method, invoked outside the loop, that only returns the changed 
             * columns. This could be, although, more error prone because the developer could 
             * easily forget to update both methods.
            */
            l_cols := change_exec_row_exec_cols(i_prof         => i_prof,
                                                i_notes        => i_notes,
                                                i_dt_take_tstz => i_dt_take_tstz,
                                                i_sysdate_tstz => i_sysdate_tstz,
                                                io_exec_row    => l_exec_row);
        
            l_exec_row_coll(i) := l_exec_row;
        END LOOP;
    
        -- Persist the data into the database
        update_exec_rows(i_lang => i_lang, i_prof => i_prof, i_exec_row_coll => l_exec_row_coll, i_cols => l_cols);
    
        -- Recalculates the plan of all the executed interventions
        recalculate_plan(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_exec_interv_coll => i_exec_interv_coll,
                         i_dt_take_tstz     => i_dt_take_tstz,
                         i_sysdate_tstz     => i_sysdate_tstz);
    
        -- Creates a next execution in the plan table (if needed)
        create_next_exec_by_intv_coll(i_lang => i_lang, i_prof => i_prof, i_exec_interv_coll => i_exec_interv_coll);
    
    END set_execs_status_execute;

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows) 
     * when the user executes a execution using a template.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_exec_interv_rec The record with all the data needed to correctly execute 
     *                          an intervention.
     * @param i_epis_documentation_id Identifier of the template record where the execution
     *                                was documented.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_status_execute_doc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_exec_interv_rec       IN pk_icnp_type.t_exec_interv_rec,
        i_epis_documentation_id IN icnp_interv_plan.id_epis_documentation%TYPE,
        i_sysdate_tstz          IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_status_execute_doc';
        l_exec_row icnp_interv_plan%ROWTYPE;
        l_cols     table_varchar;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Gets the execution row of the given identifier (i_interv_plan_id)
        l_exec_row := get_exec_row(i_interv_plan_id => i_exec_interv_rec.id_icnp_interv_plan);
    
        -- Make the necessary changes to the record
        l_cols := change_exec_row_exec_doc_cols(i_prof                  => i_prof,
                                                i_epis_documentation_id => i_epis_documentation_id,
                                                i_dt_take_tstz          => NULL,
                                                i_sysdate_tstz          => i_sysdate_tstz,
                                                io_exec_row             => l_exec_row);
    
        -- Persist the data into the database
        update_exec_row(i_lang => i_lang, i_prof => i_prof, i_exec_row => l_exec_row, i_cols => l_cols);
    
        -- We can't recalculate the plan because when the execution is made through a 
        -- template there is no dt_take
    
        -- Creates a next execution in the plan table (if needed)
        create_next_exec_by_intv_rec(i_lang => i_lang, i_prof => i_prof, i_exec_interv_rec => i_exec_interv_rec);
    
    END set_exec_status_execute_doc;

    /**
     * Makes the necessary updates to a set of execution records (icnp_interv_plan rows) 
     * when the user executes a non-template execution with vital signs.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_episode The episode identifier.
     * @param i_patient The patient identifier.
     * @param i_prof_cat The category of the logged professional.
     * @param i_exec_interv_rec The record with all the data needed to correctly execute 
     *                          an intervention.
     * @param i_notes Notes with the details about the execution.
     * @param i_dt_take_tstz Timestamp that identifies the moment in time when the 
     *                       planned execution was effectively executed.
     * @param i_vs_id Collection of read vital signs identifiers.
     * @param i_vs_val Collection with the measured values of each vital sign.
     * @param i_vs_unit_mea Collection with the identifiers of the unit measure used
     *                      for each vital sign read.
     * @param i_vs_scl_elem Collection with the identifiers of the scale used to 
     *                      measure the pain vital sign. When other vital signs are
     *                      read, the collection element should be null.
     * @param i_vs_notes The notes written while reading the vital signs. 
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
    * @param i_vs_dt Collection of read vital signs clinical date.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_status_execute_vs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_prof_cat        IN category.flg_type%TYPE,
        i_exec_interv_rec IN pk_icnp_type.t_exec_interv_rec,
        i_notes           IN icnp_interv_plan.notes%TYPE,
        i_dt_take_tstz    IN icnp_interv_plan.dt_take_tstz%TYPE,
        i_vs_id           IN table_number,
        i_vs_val          IN table_number,
        i_vs_unit_mea     IN table_number,
        i_vs_scl_elem     IN table_number,
        i_vs_notes        IN vital_sign_notes.notes%TYPE,
        i_sysdate_tstz    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_vs_dt           IN table_varchar
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_status_execute_vs';
        l_exec_row    icnp_interv_plan%ROWTYPE;
        l_cols        table_varchar;
        l_vs_read     table_number;
        l_error       t_error_out;
        l_dt_registry VARCHAR2(20 CHAR);
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_vs_id)
           OR pk_icnp_util.is_table_empty(i_vs_val)
           OR pk_icnp_util.is_table_empty(i_vs_unit_mea)
           OR pk_icnp_util.is_table_empty(i_vs_scl_elem)
           OR pk_icnp_util.is_table_empty(i_vs_dt)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'At least one of the tables with the vital signs data is empty');
        END IF;
        IF i_vs_id.count <> i_vs_val.count
           OR i_vs_id.count <> i_vs_unit_mea.count
           OR i_vs_id.count <> i_vs_scl_elem.count
           OR i_vs_id.count <> i_vs_dt.count
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The tables with the vital signs data are not equally sized');
        END IF;
    
        -- Gets the execution row of the given identifier (i_interv_plan_id)
        l_exec_row := get_exec_row(i_interv_plan_id => i_exec_interv_rec.id_icnp_interv_plan);
    
        -- Make the necessary changes to the record
        l_cols := change_exec_row_exec_cols(i_prof         => i_prof,
                                            i_notes        => i_notes,
                                            i_dt_take_tstz => i_dt_take_tstz,
                                            i_sysdate_tstz => i_sysdate_tstz,
                                            io_exec_row    => l_exec_row);
    
        -- Persist the data into the database
        update_exec_row(i_lang => i_lang, i_prof => i_prof, i_exec_row => l_exec_row, i_cols => l_cols);
    
        -- Recalculates the plan of all the executed interventions
        recalculate_plan(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_exec_interv_coll => pk_icnp_type.t_exec_interv_coll(i_exec_interv_rec),
                         i_dt_take_tstz     => i_dt_take_tstz,
                         i_sysdate_tstz     => i_sysdate_tstz);
    
        -- Creates a next execution in the plan table (if needed)
        create_next_exec_by_intv_rec(i_lang => i_lang, i_prof => i_prof, i_exec_interv_rec => i_exec_interv_rec);
    
        -- Saves the set of vital signs
        IF NOT pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                 i_episode            => i_episode,
                                                 i_prof               => i_prof,
                                                 i_pat                => i_patient,
                                                 i_vs_id              => i_vs_id,
                                                 i_vs_val             => i_vs_val,
                                                 i_id_monit           => NULL,
                                                 i_unit_meas          => i_vs_unit_mea,
                                                 i_vs_scales_elements => i_vs_scl_elem,
                                                 i_notes              => i_vs_notes,
                                                 i_prof_cat_type      => i_prof_cat,
                                                 i_dt_vs_read         => i_vs_dt,
                                                 i_epis_triage        => NULL,
                                                 i_unit_meas_convert  => i_vs_unit_mea,
                                                 o_vital_sign_read    => l_vs_read,
                                                 o_dt_registry        => l_dt_registry,
                                                 o_error              => l_error)
        THEN
            pk_icnp_util.raise_unexpected_error('pk_vital_sign.set_epis_vital_sign', l_error);
        END IF;
    
        -- Add the vital sign records (that were previously added) to icnp_epis_task
        IF NOT pk_icnp_util.is_table_empty(l_vs_read)
        THEN
            INSERT INTO icnp_epis_task
                (id_icnp_epis_task, id_icnp_epis_interv, id_task, id_icnp_interv_plan)
                SELECT seq_icnp_epis_task.nextval            id_icnp_epis_task,
                       l_exec_row.id_icnp_epis_interv        id_icnp_epis_interv,
                       vsr.id_vital_sign_read,
                       i_exec_interv_rec.id_icnp_interv_plan id_icnp_interv_plan
                  FROM vital_sign_read vsr
                 WHERE vsr.id_vital_sign_read IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                   t.column_value id_vital_sign_read
                                                    FROM TABLE(l_vs_read) t);
        END IF;
    
    END set_exec_status_execute_vs;

    --------------------------------------------------------------------------------
    -- METHODS [UPDATE EXEC STATUS FOR INTERV]
    --------------------------------------------------------------------------------

    /**
     * Gets a collection of execution identifiers that are related with a set of
     * interventions. Only a subset of all the related executions are returned, 
     * because only executions with some status (given as input) are returned.
     * 
     * For the reasons expressed above, this method should only be used by the
     * set_exec_st_xxx_for_intervs methods.
     * 
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_status Set of execution status used to filter the returned 
     *                 executions.
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    FUNCTION get_execs_gen_for_intervs
    (
        i_interv_ids IN table_number,
        i_status     IN table_varchar
    ) RETURN table_number IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'get_execs_gen_for_intervs';
        l_exec_ids table_number;
    
    BEGIN
        -- Debug message
        log_debug(c_func_name || '(...)', c_func_name);
    
        -- Check the input parameters
        IF pk_icnp_util.is_table_empty(i_status)
        THEN
            pk_alert_exceptions.raise_error(error_name_in => pk_icnp_constant.g_excep_inv_input_params,
                                            text_in       => 'The table with the status (i_status) given as input parameter is empty');
        END IF;
        IF pk_icnp_util.is_table_empty(i_interv_ids)
        THEN
            RETURN table_number();
        END IF;
    
        -- Retrieve the set of executions
        SELECT iip.id_icnp_interv_plan
          BULK COLLECT
          INTO l_exec_ids
          FROM icnp_interv_plan iip
         WHERE iip.id_icnp_epis_interv IN (SELECT /*+opt_estimate(table t rows=1)*/
                                            t.column_value id_icnp_epis_interv
                                             FROM TABLE(i_interv_ids) t)
           AND iip.flg_status IN (SELECT /*+opt_estimate(table t rows=1)*/
                                   t.column_value flg_status
                                    FROM TABLE(i_status) t);
    
        RETURN l_exec_ids;
    
    END get_execs_gen_for_intervs;

    /**
     * Marks as not executed all the execution records that are not yet executed and
     * that are related with a set of interventions. Usually this method is invoked 
     * when some action is performed on the interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see update_execs_status (g_interv_plan_status_not_exec)
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_st_notexe_for_intervs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_st_notexe_for_intervs';
        l_status   table_varchar;
        l_exec_ids table_number;
    
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
    
        -- Gets the executions associated with the interventions that must be updated
        l_status   := table_varchar(pk_icnp_constant.g_interv_plan_status_requested,
                                    pk_icnp_constant.g_interv_plan_status_pending,
                                    pk_icnp_constant.g_interv_plan_status_suspended);
        l_exec_ids := get_execs_gen_for_intervs(i_interv_ids => i_interv_ids, i_status => l_status);
    
        -- Marks the execution records as not executed
        update_execs_status(i_lang         => i_lang,
                            i_prof         => i_prof,
                            i_exec_ids     => l_exec_ids,
                            i_flg_status   => pk_icnp_constant.g_interv_plan_status_not_exec,
                            i_sysdate_tstz => i_sysdate_tstz);
    
    END set_exec_st_notexe_for_intervs;

    /**
     * Marks as suspended all the execution records that are not yet executed and
     * that are related with a set of interventions. Usually this method is invoked 
     * when some action is performed on the interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see update_execs_status (g_interv_plan_status_suspended)
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_st_susp_for_intervs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_st_susp_for_intervs';
        l_status   table_varchar;
        l_exec_ids table_number;
    
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
    
        -- Gets the executions associated with the interventions that must be updated
        l_status   := table_varchar(pk_icnp_constant.g_interv_plan_status_requested,
                                    pk_icnp_constant.g_interv_plan_status_pending);
        l_exec_ids := get_execs_gen_for_intervs(i_interv_ids => i_interv_ids, i_status => l_status);
    
        -- Marks the execution records as suspended
        update_execs_status(i_lang         => i_lang,
                            i_prof         => i_prof,
                            i_exec_ids     => l_exec_ids,
                            i_flg_status   => pk_icnp_constant.g_interv_plan_status_suspended,
                            i_sysdate_tstz => i_sysdate_tstz);
    
    END set_exec_st_susp_for_intervs;

    /**
     * Marks as requested (active) all the execution records that are suspended and
     * that are related with a set of interventions. Usually this method is invoked 
     * when some action is performed on the interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see update_execs_status (g_interv_plan_status_requested)
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_st_req_for_intervs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_interv_ids   IN table_number,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_st_req_for_intervs';
        l_status   table_varchar;
        l_exec_ids table_number;
    
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
    
        -- Gets the executions associated with the interventions that must be updated
        l_status   := table_varchar(pk_icnp_constant.g_interv_plan_status_suspended);
        l_exec_ids := get_execs_gen_for_intervs(i_interv_ids => i_interv_ids, i_status => l_status);
    
        -- Marks the execution records as requested (for execution, but not yet executed)
        update_execs_status(i_lang         => i_lang,
                            i_prof         => i_prof,
                            i_exec_ids     => l_exec_ids,
                            i_flg_status   => pk_icnp_constant.g_interv_plan_status_requested,
                            i_sysdate_tstz => i_sysdate_tstz);
    
    END set_exec_st_req_for_intervs;

    /**
     * Marks as cancelled all the execution records that are not yet executed and
     * that are related with a set of interventions. Usually this method is invoked 
     * when some action is performed on the interventions.
     * 
     * @param i_lang The professional preferred language.
     * @param i_prof The professional context [id user, id institution, id software].
     * @param i_interv_ids The set of intervention identifiers.
     * @param i_cancel_reason Cancellation reason identifier.
     * @param i_cancel_notes Notes describing the reason of the cancellation.
     * @param i_sysdate_tstz Current timestamp that should be used across all the 
     *                       functions invoked from this one.
     * 
     * @see set_execs_status_cancel
     * 
     * @author Luis Oliveira
     * @version 1.0
     * @since 12/Jun/2011 (v2.6.1)
    */
    PROCEDURE set_exec_st_cancel_for_intervs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_interv_ids    IN table_number,
        i_cancel_reason IN icnp_interv_plan.id_cancel_reason%TYPE,
        i_cancel_notes  IN icnp_interv_plan.notes_cancel%TYPE,
        i_sysdate_tstz  IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        c_func_name CONSTANT pk_icnp_type.t_function_name := 'set_exec_st_cancel_for_intervs';
        l_status   table_varchar;
        l_exec_ids table_number;
    
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
    
        -- Gets the executions associated with the interventions that must be updated
        l_status   := table_varchar(pk_icnp_constant.g_interv_plan_status_requested,
                                    pk_icnp_constant.g_interv_plan_status_pending,
                                    pk_icnp_constant.g_interv_plan_status_suspended);
        l_exec_ids := get_execs_gen_for_intervs(i_interv_ids => i_interv_ids, i_status => l_status);
    
        -- Marks the execution records as cancelled
        set_execs_status_cancel(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_exec_ids      => l_exec_ids,
                                i_cancel_reason => i_cancel_reason,
                                i_cancel_notes  => i_cancel_notes,
                                i_sysdate_tstz  => i_sysdate_tstz);
    
    END set_exec_st_cancel_for_intervs;

BEGIN
    -- Executes all the instructions needed to correctly initialize the package
    initialize();

END pk_icnp_exec;
/
