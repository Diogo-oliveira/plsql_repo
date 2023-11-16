/*-- Last Change Revision: $Rev: 2027401 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:07 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE BODY pk_order_recurrence_api_db IS

    -- purpose: order recurrence api database package

    -- declared exceptions
    e_user_exception EXCEPTION;

    /********************************************************************************************
    * get order plan executions based in supplied timestamp intervals
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_plan           the order recurrence plan id
    * @param       i_plan_start_date      the order start interval execution plan
    * @param       i_plan_end_date        the order end interval execution plan
    * @param       i_proc_from_day        process recurrence from this timestamp (if defined)
    * @param       i_proc_from_exec_nr    process recurrence from this execution number (if defined)
    * @param       o_order_plan           cursor with the execution plan for the given interval
    * @param       o_last_exec_reached    flag that indicates if the last execution was processed for given plan
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @value       o_last_exec_reached    {*} 'Y' last execution was processed in this function's plan interval
    *                                     {*} 'N' last execution wasn't processed in this function's plan interval
    *
    * @author                             Carlos Loureiro
    * @since                              07-APR-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_plan        IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_plan_start_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_plan_end_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_proc_from_day     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_proc_from_exec_nr IN PLS_INTEGER DEFAULT NULL,
        o_order_plan        OUT pk_types.cursor_type,
        o_last_exec_reached OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_plan t_tbl_order_recurr_plan;
    BEGIN
        -- call pk_order_recurrence_core.get_order_plan function
        IF NOT pk_order_recurrence_core.get_order_recurr_plan(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_order_plan        => i_order_plan,
                                                              i_plan_start_date   => i_plan_start_date,
                                                              i_plan_end_date     => i_plan_end_date,
                                                              i_proc_from_day     => i_proc_from_day,
                                                              i_proc_from_exec_nr => i_proc_from_exec_nr,
                                                              o_order_plan        => l_order_plan,
                                                              o_last_exec_reached => o_last_exec_reached,
                                                              o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'open o_order_plan cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
        OPEN o_order_plan FOR
            SELECT plan.id_order_recurrence_plan, plan.exec_number, plan.exec_timestamp
              FROM TABLE(CAST(l_order_plan AS t_tbl_order_recurr_plan)) plan
             ORDER BY plan.exec_number;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_RECURR_PLAN',
                                              o_error);
            pk_types.open_my_cursor(o_order_plan);
            RETURN FALSE;
    END get_order_recurr_plan;

    /********************************************************************************************
    * get order plan executions based in supplied timestamp intervals
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_plan           the order recurrence plan id
    * @param       i_plan_start_date      the order start interval execution plan
    * @param       i_plan_end_date        the order end interval execution plan
    * @param       i_proc_from_day        process recurrence from this timestamp (if defined)
    * @param       i_proc_from_exec_nr    process recurrence from this execution number (if defined)
    * @param       o_order_plan           table collection with the execution plan for the given interval
    * @param       o_last_exec_reached    flag that indicates if the last execution was processed for given plan
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @value       o_last_exec_reached    {*} 'Y' last execution was processed in this function's plan interval
    *                                     {*} 'N' last execution wasn't processed in this function's plan interval
    *
    * @author                             Carlos Loureiro
    * @since                              02-MAY-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_plan        IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_plan_start_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_plan_end_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_proc_from_day     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_proc_from_exec_nr IN PLS_INTEGER DEFAULT NULL,
        o_order_plan        OUT t_tbl_order_recurr_plan,
        o_last_exec_reached OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.get_order_plan function
        IF NOT pk_order_recurrence_core.get_order_recurr_plan(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_order_plan        => i_order_plan,
                                                              i_plan_start_date   => i_plan_start_date,
                                                              i_plan_end_date     => i_plan_end_date,
                                                              i_proc_from_day     => i_proc_from_day,
                                                              i_proc_from_exec_nr => i_proc_from_exec_nr,
                                                              o_order_plan        => o_order_plan,
                                                              o_last_exec_reached => o_last_exec_reached,
                                                              o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_plan function';
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
                                              'GET_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END get_order_recurr_plan;

    /********************************************************************************************
    * get order plan executions based in supplied timestamp intervals
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_plan           the order recurrence plan id
    * @param       i_plan_start_date      the order start interval execution plan
    * @param       i_plan_end_date        the order end interval execution plan
    * @param       i_proc_from_day        process recurrence from this timestamp (if defined)
    * @param       i_proc_from_exec_nr    process recurrence from this execution number (if defined)
    *
    * @return      table collection with the execution plan for the given interval
    *
    * @author                             Joao Martins
    * @since                              26-MAY-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_plan        IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_plan_start_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_plan_end_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_proc_from_day     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_proc_from_exec_nr IN PLS_INTEGER DEFAULT NULL
    ) RETURN t_tbl_order_recurr_plan IS
        l_plan              t_tbl_order_recurr_plan;
        l_last_exec_reached VARCHAR2(1 CHAR);
        l_error             t_error_out;
    BEGIN
        -- call pk_order_recurrence_core.get_order_plan function
        IF NOT pk_order_recurrence_core.get_order_recurr_plan(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_order_plan        => i_order_plan,
                                                              i_plan_start_date   => i_plan_start_date,
                                                              i_plan_end_date     => i_plan_end_date,
                                                              i_proc_from_day     => i_proc_from_day,
                                                              i_proc_from_exec_nr => i_proc_from_exec_nr,
                                                              o_order_plan        => l_plan,
                                                              o_last_exec_reached => l_last_exec_reached,
                                                              o_error             => l_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
        RETURN l_plan;
    END get_order_recurr_plan;

    /********************************************************************************************
    * create a temporary order recurrence plan
    *
    * @param       i_lang                             preferred language id
    * @param       i_prof                             professional structure
    * @param       i_order_recurr_area                order recurrence area internal name
    * @param       i_order_recurr_option              order recurrence option id (optional)
    * @param       i_flg_include_start_dt_in_plan     flag that indicates if start date must be included in the plan or not (optional)
    * @param       o_order_recurr_desc                order recurrence description
    * @param       o_order_recurr_option              order recurrence option id
    * @param       o_start_date                       calculated order start date
    * @param       o_ocurrences                       number of occurrences considered in this plan
    * @param       o_duration                         duration considered in this plan
    * @param       o_unit_meas_duration               duration unit measure considered in this plan
    * @param       o_end_date                         calculated order plan end date
    * @param       o_flg_end_by_editable              flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan                generated order recurrence plan id
    * @param       o_error                            error structure for exception handling
    *
    * @value       i_flg_include_start_dt_in_plan     {*} 'Y' include start date in the execution plan
    *                                                 {*} 'N' not include start date in the execution plan
    *
    * @value       o_flg_end_by_editable              {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                                 {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                        true on success, otherwise false
    *
    * @author                                     Tiago Silva
    * @since                                      26-APR-2011
    ********************************************************************************************/
    FUNCTION create_order_recurr_plan
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_order_recurr_area            IN order_recurr_area.internal_name%TYPE,
        i_order_recurr_option          IN order_recurr_option.id_order_recurr_option%TYPE DEFAULT NULL,
        i_flg_include_start_dt_in_plan IN VARCHAR2 DEFAULT 'N',
        o_order_recurr_desc            OUT VARCHAR2,
        o_order_recurr_option          OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date                   OUT order_recurr_plan.start_date%TYPE,
        o_occurrences                  OUT order_recurr_plan.occurrences%TYPE,
        o_duration                     OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration           OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                     OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable          OUT VARCHAR2,
        o_order_recurr_plan            OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.create_order_recurr_plan function
        IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                         => i_lang,
                                                                 i_prof                         => i_prof,
                                                                 i_order_recurr_area            => i_order_recurr_area,
                                                                 i_order_recurr_option          => i_order_recurr_option,
                                                                 i_flg_include_start_dt_in_plan => i_flg_include_start_dt_in_plan,
                                                                 o_order_recurr_desc            => o_order_recurr_desc,
                                                                 o_order_recurr_option          => o_order_recurr_option,
                                                                 o_start_date                   => o_start_date,
                                                                 o_occurrences                  => o_occurrences,
                                                                 o_duration                     => o_duration,
                                                                 o_unit_meas_duration           => o_unit_meas_duration,
                                                                 o_end_date                     => o_end_date,
                                                                 o_flg_end_by_editable          => o_flg_end_by_editable,
                                                                 o_order_recurr_plan            => o_order_recurr_plan,
                                                                 o_error                        => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
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
                                              'CREATE_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END create_order_recurr_plan;

    /********************************************************************************************
    * set a temporary order recurrence plan as definitive (final status)
    *
    * @param       i_lang                      preferred language id
    * @param       i_prof                      professional structure
    * @param       i_order_recurr_plan         order recurrence plan id
    * @param       o_order_recurr_option       order recurrence option id
    * @param       o_final_order_recurr_plan   final order recurrence plan id
    * @param       o_error                     error structure for exception handling
    *
    * @return      boolean                     true on success, otherwise false
    *
    * @author                                  Tiago Silva
    * @since                                   26-APR-2011
    ********************************************************************************************/
    FUNCTION set_order_recurr_plan
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_order_recurr_plan       IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_order_recurr_option     OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_final_order_recurr_plan OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- call pk_order_recurrence_core.set_order_recurr_plan function
        IF NOT pk_order_recurrence_core.set_order_recurr_plan(i_lang                    => i_lang,
                                                              i_prof                    => i_prof,
                                                              i_order_recurr_plan       => i_order_recurr_plan,
                                                              o_order_recurr_option     => o_order_recurr_option,
                                                              o_final_order_recurr_plan => o_final_order_recurr_plan,
                                                              o_error                   => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_plan function';
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
                                              'SET_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END set_order_recurr_plan;

    /********************************************************************************************
    * decrement last_exec_order when execution order has canceled
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Pedro Henriques
    * @since                                19-MAY-2016
    ********************************************************************************************/
    FUNCTION cancel_execution_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_order_recurrence_core.cancel_execution_order(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_order_recurr_plan => i_order_recurr_plan,
                                                               o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.cancel_execution_order function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    
        RETURN TRUE;
    END;

    /********************************************************************************************
    * decrement last_exec_order when execution order has canceled
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Pedro Henriques
    * @since                                19-MAY-2016
    ********************************************************************************************/
    FUNCTION update_order_control_last_exec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_control.id_order_recurr_plan%TYPE,
        i_dt_last_processed IN order_recurr_control.dt_last_processed%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_order_recurrence_core.update_order_control_last_exec(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_order_recurr_plan => i_order_recurr_plan,
                                                                       i_dt_last_processed => i_dt_last_processed,
                                                                       o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.cancel_execution_order function';
            RAISE e_user_exception;
        END IF;
        RETURN TRUE;
    
        RETURN TRUE;
    END update_order_control_last_exec;

    /********************************************************************************************
    * cancel a temporary order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                26-APR-2011
    ********************************************************************************************/
    FUNCTION cancel_order_recurr_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.cancel_order_recurr_plan function
        IF NOT pk_order_recurrence_core.cancel_order_recurr_plan(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_order_recurr_plan => i_order_recurr_plan,
                                                                 o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.cancel_order_recurr_plan function';
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
                                              'cancel_order_recurr_plan',
                                              o_error);
            RETURN FALSE;
    END cancel_order_recurr_plan;

    /********************************************************************************************
    * prepare the order plan executions based in plan's area and interval configurations (To Procedures)
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_plan           list of order recurrence plan id
    * @param       o_order_plan_exec      table collection with the execution plan
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Pedro Henriques
    * @since                              11-MAY-2016
    ********************************************************************************************/
    FUNCTION prepare_order_recurr_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_order_plan IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- call pk_order_recurrence_core.cancel_order_recurr_plan function
        IF NOT pk_order_recurrence_core.prepare_order_recurr_plan(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_order_plan => i_order_plan,
                                                                  o_error      => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.prepare_order_recurr_plan function';
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
                                              'PREPARE_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END prepare_order_recurr_plan;

    /********************************************************************************************
    * prepare the order plan executions based in plan's area and interval configurations
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_plan           list of order recurrence plan id
    * @param       o_order_plan_exec      table collection with the execution plan
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Ana Monteiro
    * @since                              09-MAY-2011
    ********************************************************************************************/
    FUNCTION prepare_order_recurr_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_order_plan      IN table_number,
        o_order_plan_exec OUT t_tbl_order_recurr_plan,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -- call pk_order_recurrence_core.prepare_order_recurr_plan function
        IF NOT pk_order_recurrence_core.prepare_order_recurr_plan(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_order_plan      => i_order_plan,
                                                                  o_order_plan_exec => o_order_plan_exec,
                                                                  o_error           => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.prepare_order_recurr_plan function';
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
                                              'PREPARE_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END prepare_order_recurr_plan;

    /********************************************************************************************
    * get order recurrence plan description
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_order_recurr_plan        order recurrence plan id
    * @param       i_flg_show_date            flag that indicates if dates can be displayed or not (Y - Yes (default); N - No)
    *
    * @return      varchar2                   order recurrence plan description
    *
    * @author                                 Carlos Loureiro
    * @since                                  12-MAY-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_plan_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_show_date     IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2 IS
    BEGIN
        -- get order recurrence plan frequency description
        RETURN pk_order_recurrence_core.get_order_recurr_plan_desc(i_lang              => i_lang,
                                                                   i_prof              => i_prof,
                                                                   i_order_recurr_plan => i_order_recurr_plan,
                                                                   i_flg_show_date     => i_flg_show_date);
    END get_order_recurr_plan_desc;

    /********************************************************************************************
    * create and set as final an order recurrence plan based on the given order recurrence option
    * and start date
    *
    * @param       i_lang                             preferred language id
    * @param       i_prof                             professional structure
    * @param       i_order_recurr_area                order recurrence area internal name
    * @param       i_order_recurr_option              order recurrence option
    * @param       i_start_date                       desired order recurrence plan start date
    * @param       i_flg_include_start_dt_in_plan     flag that indicates if start date must be included in the plan or not (optional)
    * @param       o_start_date                       calculated order recurrence plan start date
    * @param       o_order_recurr_plan                generated order recurrence plan id
    * @param       o_error                            error structure for exception handling
    *
    * @value       i_flg_include_start_dt_in_plan     {*} 'Y' include start date in the execution plan
    *                                                 {*} 'N' not include start date in the execution plan
    *
    * @return      boolean                            true on success, otherwise false
    *
    * @author                                         Carlos Loureiro
    * @since                                          23-MAY-2011
    ********************************************************************************************/
    FUNCTION create_n_set_order_recurr_plan
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_order_recurr_area            IN order_recurr_area.internal_name%TYPE,
        i_order_recurr_option          IN order_recurr_option.id_order_recurr_option%TYPE,
        i_start_date                   IN order_recurr_plan.start_date%TYPE,
        i_flg_include_start_dt_in_plan IN VARCHAR2 DEFAULT 'N',
        o_start_date                   OUT order_recurr_plan.start_date%TYPE,
        o_order_recurr_plan            OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_option                    order_recurr_option.id_order_recurr_option%TYPE;
        l_plan_desc                 VARCHAR2(1000 CHAR);
        l_start_date                TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date                  TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_end_by_editable       VARCHAR2(1 CHAR);
        l_occurrences               order_recurr_plan.occurrences%TYPE;
        l_duration                  order_recurr_plan.duration%TYPE;
        l_unit_meas_duration        order_recurr_plan.id_unit_meas_duration%TYPE;
        l_created_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE;
        l_final_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_option       order_recurr_plan.id_order_recurr_option%TYPE;
    BEGIN
    
        -- create a temporary order recurrence plan based on the default order recurrence option
        IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                         => i_lang,
                                                                 i_prof                         => i_prof,
                                                                 i_order_recurr_area            => i_order_recurr_area,
                                                                 i_order_recurr_option          => i_order_recurr_option,
                                                                 i_flg_include_start_dt_in_plan => i_flg_include_start_dt_in_plan,
                                                                 o_order_recurr_desc            => l_plan_desc,
                                                                 o_order_recurr_option          => l_option,
                                                                 o_start_date                   => l_start_date,
                                                                 o_occurrences                  => l_occurrences,
                                                                 o_duration                     => l_duration,
                                                                 o_unit_meas_duration           => l_unit_meas_duration,
                                                                 o_end_date                     => l_end_date,
                                                                 o_flg_end_by_editable          => l_flg_end_by_editable,
                                                                 o_order_recurr_plan            => l_created_order_recurr_plan, -- the created plan id
                                                                 o_error                        => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- set new order recurrence instructions for a given order recurrence plan
        IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                      i_prof                => i_prof,
                                                                      i_order_recurr_plan   => l_created_order_recurr_plan,
                                                                      i_start_date          => i_start_date,
                                                                      i_occurrences         => l_occurrences,
                                                                      i_duration            => l_duration,
                                                                      i_unit_meas_duration  => l_unit_meas_duration,
                                                                      i_end_date            => l_end_date,
                                                                      o_order_recurr_desc   => l_plan_desc,
                                                                      o_order_recurr_option => l_order_recurr_option,
                                                                      o_start_date          => l_start_date,
                                                                      o_occurrences         => l_occurrences,
                                                                      o_duration            => l_duration,
                                                                      o_unit_meas_duration  => l_unit_meas_duration,
                                                                      o_end_date            => l_end_date,
                                                                      o_flg_end_by_editable => l_flg_end_by_editable,
                                                                      o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
    
        -- set a temporary order recurrence plan as definitive (final status)
        IF NOT pk_order_recurrence_core.set_order_recurr_plan(i_lang                    => i_lang,
                                                              i_prof                    => i_prof,
                                                              i_order_recurr_plan       => l_created_order_recurr_plan,
                                                              o_order_recurr_option     => l_order_recurr_option,
                                                              o_final_order_recurr_plan => l_final_order_recurr_plan,
                                                              o_error                   => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- assign output variables
        o_start_date        := l_start_date;
        o_order_recurr_plan := l_final_order_recurr_plan;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_N_SET_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END create_n_set_order_recurr_plan;

    /********************************************************************************************
    * copy from existing order recurrence plan, with start date adjustment
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_area      order recurrence area internal name
    * @param       i_order_recurr_plan_from order recurrence plan to copy from
    * @param       i_flg_force_temp_plan    duplicated plan can be forced as temporary or not
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    default order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan      new order recurrence plan id for created copy
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @value       i_flg_force_temp_plan    {*} 'Y' duplicated plan shall be temporary
    *                                       {*} 'N' duplicate plan assigning original status value
    *
    * @author                               Carlos Loureiro
    * @since                                20-JUN-2011
    ********************************************************************************************/
    FUNCTION copy_from_order_recurr_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_recurr_area      IN order_recurr_area.internal_name%TYPE,
        i_order_recurr_plan_from IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_force_temp_plan    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_order_recurr_desc      OUT VARCHAR2,
        o_order_recurr_option    OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date             OUT order_recurr_plan.start_date%TYPE,
        o_occurrences            OUT order_recurr_plan.occurrences%TYPE,
        o_duration               OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration     OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc          OUT VARCHAR2,
        o_end_date               OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable    OUT VARCHAR2,
        o_order_recurr_plan      OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.copy_from_order_recurr_plan function
        IF NOT pk_order_recurrence_core.copy_from_order_recurr_plan(i_lang                   => i_lang,
                                                                    i_prof                   => i_prof,
                                                                    i_order_recurr_area      => i_order_recurr_area,
                                                                    i_order_recurr_plan_from => i_order_recurr_plan_from,
                                                                    i_flg_force_temp_plan    => i_flg_force_temp_plan,
                                                                    o_order_recurr_desc      => o_order_recurr_desc,
                                                                    o_order_recurr_option    => o_order_recurr_option,
                                                                    o_start_date             => o_start_date,
                                                                    o_occurrences            => o_occurrences,
                                                                    o_duration               => o_duration,
                                                                    o_unit_meas_duration     => o_unit_meas_duration,
                                                                    o_end_date               => o_end_date,
                                                                    o_flg_end_by_editable    => o_flg_end_by_editable,
                                                                    o_order_recurr_plan      => o_order_recurr_plan,
                                                                    o_error                  => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.copy_from_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
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
                                              'COPY_FROM_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END copy_from_order_recurr_plan;

    /********************************************************************************************
    * get order recurrence plan status
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_order_recurr_plan        order recurrence plan id
    * @param       o_flg_status               order recurrence plan status
    * @param       o_last_exec_order          last created execution number for this plan
    * @param       o_dt_last_exec             last created execution timestamp for this plan
    * @param       o_error                    error structure for exception handling
    *
    * @value       o_flg_status               {*} 'A' active plan (last execution still not created)
    *                                         {*} 'F' finished plan (last execution already created)
    *                                         {*} 'O' outdated (or cancelled)
    *
    * @return      boolean                    true on success, otherwise false
    *
    * @author                                 Carlos Loureiro
    * @since                                  29-JUN-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_plan_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_flg_status        OUT order_recurr_control.flg_status%TYPE,
        o_last_exec_order   OUT order_recurr_control.last_exec_order%TYPE,
        o_dt_last_exec      OUT order_recurr_control.dt_last_exec%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.get_order_recurr_plan_status
        IF NOT pk_order_recurrence_core.get_order_recurr_plan_status(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_order_recurr_plan => i_order_recurr_plan,
                                                                     o_flg_status        => o_flg_status,
                                                                     o_last_exec_order   => o_last_exec_order,
                                                                     o_dt_last_exec      => o_dt_last_exec,
                                                                     o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_plan_status function';
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
                                              'GET_ORDER_RECURR_PLAN_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_order_recurr_plan_status;

    /********************************************************************************************
    * set an extra execution if there is no active executions within an order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       i_active_executions      number of active executions
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                28-JUL-2011
    ********************************************************************************************/
    FUNCTION set_active_executions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_active_executions IN NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- set active executions
        IF NOT pk_order_recurrence_core.set_active_executions(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_order_recurr_plan => i_order_recurr_plan,
                                                              i_active_executions => i_active_executions,
                                                              o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_active_executions function';
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
                                              'SET_ACTIVE_EXECUTIONS',
                                              o_error);
            RETURN FALSE;
    END set_active_executions;

    /********************************************************************************************
    * set a new order recurrence option for a given order recurrence plan
    *
    * @param       i_lang                         preferred language id
    * @param       i_prof                         professional structure
    * @param       i_order_recurr_plan            order recurrence plan id
    * @param       i_order_recurr_option          order recurrence option id
    * @param       o_order_recurr_desc            order recurrence description
    * @param       o_start_date                   calculated order start date
    * @param       o_ocurrences                   number of occurrences considered in this plan
    * @param       o_duration                     duration considered in this plan
    * @param       o_unit_meas_duration           duration unit measure considered in this plan
    * @param       o_end_date                     calculated order plan end date
    * @param       o_flg_end_by_editable          flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_error                        error structure for exception handling
    *
    * @value       o_flg_end_by_editable          {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                             {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                        true on success, otherwise false
    *
    * @author                                     Carlos Loureiro
    * @since                                      30-AUG-2011
    ********************************************************************************************/
    FUNCTION set_order_recurr_option
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plan   IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE,
        o_order_recurr_desc   OUT VARCHAR2,
        o_start_date          OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date            OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_end_by_editable OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.set_order_recurr_option function
        IF NOT pk_order_recurrence_core.set_order_recurr_option(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_order_recurr_plan   => i_order_recurr_plan,
                                                                i_order_recurr_option => i_order_recurr_option,
                                                                o_order_recurr_desc   => o_order_recurr_desc,
                                                                o_start_date          => o_start_date,
                                                                o_occurrences         => o_occurrences,
                                                                o_duration            => o_duration,
                                                                o_unit_meas_duration  => o_unit_meas_duration,
                                                                o_end_date            => o_end_date,
                                                                o_flg_end_by_editable => o_flg_end_by_editable,
                                                                o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_option function';
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
                                              'SET_ORDER_RECURR_OPTION',
                                              o_error);
            RETURN FALSE;
    END set_order_recurr_option;

    /********************************************************************************************
    * update execution number/timestamp and adjust remain plan executions
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       i_execution_number       execution number
    * @param       i_execution_timestamp    execution timestamp
    * @param       i_flg_need_new_plan      indicates that a new plan should be created for this
    *                                       update
    * @param       o_order_plan_exec        table collection with the execution plan
    * @param       o_order_recurr_plan      update plan (it will be equal to i_order_recurr_plan
    *                                       if a new plan is not needed)
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @value       i_flg_need_new_plan      {*} 'Y' a new plan should be considered in this update
    *                                       {*} 'N' re-use plan (o_order_recurr_plan=i_order_recurr_plan)
    *
    * @author                               Carlos Loureiro
    * @since                                01-SEP-2011
    ********************************************************************************************/
    FUNCTION update_execution_plan
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plan   IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_execution_number    IN PLS_INTEGER,
        i_execution_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_need_new_plan   IN VARCHAR2,
        o_order_plan_exec     OUT t_tbl_order_recurr_plan,
        o_order_recurr_plan   OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.update_execution_plan function
        IF NOT pk_order_recurrence_core.update_execution_plan(i_lang                => i_lang,
                                                              i_prof                => i_prof,
                                                              i_order_recurr_plan   => i_order_recurr_plan,
                                                              i_execution_number    => i_execution_number,
                                                              i_execution_timestamp => i_execution_timestamp,
                                                              i_flg_need_new_plan   => i_flg_need_new_plan,
                                                              o_order_plan_exec     => o_order_plan_exec,
                                                              o_order_recurr_plan   => o_order_recurr_plan,
                                                              o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.update_execution_plan function';
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
                                              'UPDATE_EXECUTION_PLAN',
                                              o_error);
            RETURN FALSE;
    END update_execution_plan;

    /********************************************************************************************
    * set a temporary order recurrence plan as definitive (final status) and set as deprecated
    * the edited plan
    *
    * @param       i_lang                      preferred language id
    * @param       i_prof                      professional structure
    * @param       i_order_recurr_plan_old     order recurrence plan id that was edited
    * @param       i_order_recurr_plan_new     new order recurrence plan id to replace old one
    * @param       i_flg_discard_old_plan      flag that indicates if edited plan should be discarded or not
    * @param       o_order_recurr_option       order recurrence option id
    * @param       o_final_order_recurr_plan   final order recurrence plan id
    * @param       o_error                     error structure for exception handling
    *
    * @return      boolean                     true on success, otherwise false
    *
    * @value       i_flg_discard_old_plan      {*} 'Y' old plan will be discarded (job no longer processes old plan)
    *                                          {*} 'N' old plan will be considered in job execution
    *
    * @author                                  Carlos Loureiro
    * @since                                   11-OCT-2011
    ********************************************************************************************/
    FUNCTION set_for_edit_order_recurr_plan
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_order_recurr_plan_old   IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_order_recurr_plan_new   IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_discard_old_plan    IN VARCHAR2,
        o_order_recurr_option     OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_final_order_recurr_plan OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.set_for_edit_order_recurr_plan function
        IF NOT pk_order_recurrence_core.set_for_edit_order_recurr_plan(i_lang                    => i_lang,
                                                                       i_prof                    => i_prof,
                                                                       i_order_recurr_plan_old   => i_order_recurr_plan_old,
                                                                       i_order_recurr_plan_new   => i_order_recurr_plan_new,
                                                                       i_flg_discard_old_plan    => i_flg_discard_old_plan,
                                                                       o_order_recurr_option     => o_order_recurr_option,
                                                                       o_final_order_recurr_plan => o_final_order_recurr_plan,
                                                                       o_error                   => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_for_edit_order_recurr_plan function';
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
                                              'SET_FOR_EDIT_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END set_for_edit_order_recurr_plan;

    /********************************************************************************************
    * get order recurrence instructions
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_plan             the order recurrence plan
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_duration_desc          duration description
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Carlos Loureiro
    * @since                                26-OCT-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_plan          IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT order_recurr_plan.start_date%TYPE,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_duration_desc       OUT VARCHAR2,
        o_end_date            OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.get_order_recurr_instructions function
        IF NOT pk_order_recurrence_core.get_order_recurr_instructions(i_lang                => i_lang,
                                                                      i_prof                => i_prof,
                                                                      i_order_plan          => i_order_plan,
                                                                      o_order_recurr_desc   => o_order_recurr_desc,
                                                                      o_order_recurr_option => o_order_recurr_option,
                                                                      o_start_date          => o_start_date,
                                                                      o_occurrences         => o_occurrences,
                                                                      o_duration            => o_duration,
                                                                      o_unit_meas_duration  => o_unit_meas_duration,
                                                                      o_end_date            => o_end_date,
                                                                      o_flg_end_by_editable => o_flg_end_by_editable,
                                                                      o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
    
        -- process duration description
        IF o_duration IS NOT NULL
        THEN
            o_duration_desc := o_duration || ' ' ||
                               pk_unit_measure.get_unit_measure_description(i_lang, i_prof, o_unit_meas_duration);
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
                                              'GET_ORDER_RECURR_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END get_order_recurr_instructions;

    /********************************************************************************************
    * get next execution
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_interv_presc_det         order recurrence plan id
    * @param       o_plan_start_date          next date execution (NULL if no execution)
    *
    * @return      Boolean     
    *
    * @author                                 Pedro Henriques
    * @since                                  23-May-2016
    ********************************************************************************************/
    FUNCTION get_next_execution
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_is_edit             IN NUMBER DEFAULT 0,
        i_to_execute          IN VARCHAR2 DEFAULT 'N',
        i_id_order_recurrence IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_dt_next             IN VARCHAR2,
        i_flg_next_change     IN VARCHAR2 DEFAULT 'N',
        o_flag_recurr_control OUT order_recurr_control.flg_status%TYPE,
        o_finish_recurr       OUT VARCHAR2,
        o_plan_start_date     OUT order_recurr_plan.start_date%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_order_recurrence_core.get_next_execution(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_is_edit             => i_is_edit,
                                                           i_to_execute          => i_to_execute,
                                                           i_id_order_recurrence => i_id_order_recurrence,
                                                           i_dt_next             => i_dt_next,
                                                           i_flg_next_change     => i_flg_next_change,
                                                           o_flag_recurr_control => o_flag_recurr_control,
                                                           o_finish_recurr       => o_finish_recurr,
                                                           o_plan_start_date     => o_plan_start_date,
                                                           o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_next_execution';
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error',
                                            text_in       => g_error,
                                            name1_in      => 'function_name',
                                            value1_in     => 'get_next_execution');
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_next_execution;

    /********************************************************************************************
    * get order recurrence instructions
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_order_recurr_plan        order recurrence plan id
    *
    * @return      t_recurr_plan_info_rec     Object type with recurrence instructions
    *
    * @author                                 Ariel Machado
    * @since                                  09-Jan-2014
    ********************************************************************************************/
    FUNCTION get_order_recurr_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN t_recurr_plan_info_rec IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_order_recurr_plan_info';
        l_error         t_error_out;
        l_rec_plan_info t_recurr_plan_info_rec := t_recurr_plan_info_rec(NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL);
    BEGIN
    
        IF NOT pk_order_recurrence_api_db.get_order_recurr_instructions(i_lang                => i_lang,
                                                                        i_prof                => i_prof,
                                                                        i_order_plan          => i_order_recurr_plan,
                                                                        o_order_recurr_desc   => l_rec_plan_info.order_recurr_desc,
                                                                        o_order_recurr_option => l_rec_plan_info.order_recurr_option,
                                                                        o_start_date          => l_rec_plan_info.start_date,
                                                                        o_occurrences         => l_rec_plan_info.occurrences,
                                                                        o_duration            => l_rec_plan_info.duration,
                                                                        o_unit_meas_duration  => l_rec_plan_info.unit_meas_duration,
                                                                        o_duration_desc       => l_rec_plan_info.o_duration_desc,
                                                                        o_end_date            => l_rec_plan_info.end_date,
                                                                        o_flg_end_by_editable => l_rec_plan_info.flg_end_by_editable,
                                                                        o_error               => l_error)
        THEN
            g_error := 'error found while calling PK_ORDER_RECURRENCE_API_DB.GET_ORDER_RECURR_INSTRUCTIONS';
            pk_alert_exceptions.raise_error(error_name_in => 'e_call_error',
                                            text_in       => g_error,
                                            name1_in      => 'function_name',
                                            value1_in     => k_function_name);
        END IF;
    
        RETURN l_rec_plan_info;
    
    END get_order_recurr_instructions;

    /********************************************************************************************
    * get default order recurrence option
    *
    * @param       i_lang                       preferred language id
    * @param       i_prof                       professional structure
    * @param       i_order_recurr_area          order recurrence area internal name
    * @param       o_id_order_recurr_option     order recurrence option id
    * @param       o_error                      error structure for exception handling
    *
    * @return      boolean                      true on success, otherwise false
    *
    * @author                                   Tiago Silva
    * @since                                    19-NOV-2013
    ********************************************************************************************/
    FUNCTION get_def_order_recurr_option
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_recurr_area      IN order_recurr_area.internal_name%TYPE,
        o_id_order_recurr_option OUT NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- call pk_order_recurrence_core.get_def_order_recurr_option function
        IF NOT pk_order_recurrence_core.get_def_order_recurr_option(i_lang                   => i_lang,
                                                                    i_prof                   => i_prof,
                                                                    i_order_recurr_area      => i_order_recurr_area,
                                                                    o_id_order_recurr_option => o_id_order_recurr_option,
                                                                    o_error                  => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_def_order_recurr_option function';
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
                                              'GET_DEF_ORDER_RECURR_OPTION',
                                              o_error);
            RETURN FALSE;
    END get_def_order_recurr_option;

    /********************************************************************************************
    * get order recurrence option description
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_order_recurr_option      order recurrence option id
    * @param       o_error                    error structure for exception handling
    *
    * @return      varchar2                   order recurrence option description
    *
    * @author                                 Tiago Silva
    * @since                                  19-NOV-2013
    ********************************************************************************************/
    FUNCTION get_order_recurr_option_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        -- call pk_order_recurrence_core.get_order_recurr_option_desc function
        RETURN pk_order_recurrence_core.get_order_recurr_option_desc(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_order_recurr_option => i_order_recurr_option);
    
    END get_order_recurr_option_desc;

    /********************************************************************************************
    * set order recurrence plan as finished (no more executions to process)
    *
    * @param       i_lang                      preferred language id
    * @param       i_prof                      professional structure
    * @param       i_order_recurr_plan         order recurrence plan id
    * @param       o_error                     error structure for exception handling
    *
    * @return      boolean                     true on success, otherwise false
    *
    * @author                                  Tiago Silva
    * @since                                   10-MAR-2011
    ********************************************************************************************/
    FUNCTION set_order_recurr_plan_finish
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- call pk_order_recurrence_core.set_order_recurr_plan_finish function
        IF NOT pk_order_recurrence_core.set_order_recurr_plan_finish(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_order_recurr_plan => i_order_recurr_plan,
                                                                     o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_plan_finish function';
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
                                              'set_order_recurr_plan_finish',
                                              o_error);
            RETURN FALSE;
    END set_order_recurr_plan_finish;

    FUNCTION create_order_recurr_plan_api
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_order_recurr_plan            IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_order_recurr_area            IN order_recurr_area.internal_name%TYPE,
        i_option_id_content            IN order_recurr_option.id_content%TYPE,
        i_start_date                   IN VARCHAR2,
        i_flg_include_start_dt_in_plan IN VARCHAR2 DEFAULT 'N',
        i_end_date                     IN VARCHAR2,
        i_occurrences                  IN order_recurr_plan.occurrences%TYPE,
        i_duration                     IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration           IN order_recurr_plan.id_unit_meas_duration%TYPE,
        o_order_recurr_plan            OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_option                    order_recurr_option.id_order_recurr_option%TYPE;
        l_plan_desc                 VARCHAR2(1000 CHAR);
        l_start_date                TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date                  TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_end_by_editable       VARCHAR2(1 CHAR);
        l_occurrences               order_recurr_plan.occurrences%TYPE;
        l_duration                  order_recurr_plan.duration%TYPE;
        l_unit_meas_duration        order_recurr_plan.id_unit_meas_duration%TYPE;
        l_created_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE;
        l_final_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_option       order_recurr_plan.id_order_recurr_option%TYPE;
    BEGIN
    
        BEGIN
            SELECT a.id_order_recurr_option
              INTO l_option
              FROM order_recurr_option a
             WHERE a.id_content = i_option_id_content;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END;
    
        -- create a temporary order recurrence plan based on the default order recurrence option
        IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                         => i_lang,
                                                                 i_prof                         => i_prof,
                                                                 i_order_recurr_area            => i_order_recurr_area,
                                                                 i_order_recurr_option          => l_option,
                                                                 i_flg_include_start_dt_in_plan => i_flg_include_start_dt_in_plan,
                                                                 o_order_recurr_desc            => l_plan_desc,
                                                                 o_order_recurr_option          => l_option,
                                                                 o_start_date                   => l_start_date,
                                                                 o_occurrences                  => l_occurrences,
                                                                 o_duration                     => l_duration,
                                                                 o_unit_meas_duration           => l_unit_meas_duration,
                                                                 o_end_date                     => l_end_date,
                                                                 o_flg_end_by_editable          => l_flg_end_by_editable,
                                                                 o_order_recurr_plan            => l_created_order_recurr_plan, -- the created plan id
                                                                 o_error                        => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- set new order recurrence instructions for a given order recurrence plan
        IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang                => i_lang,
                                                                      i_prof                => i_prof,
                                                                      i_order_recurr_plan   => l_created_order_recurr_plan,
                                                                      i_start_date          => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                                             i_prof      => i_prof,
                                                                                                                             i_timestamp => i_start_date,
                                                                                                                             i_timezone  => NULL),
                                                                      i_occurrences         => i_occurrences,
                                                                      i_duration            => i_duration,
                                                                      i_unit_meas_duration  => i_unit_meas_duration,
                                                                      i_end_date            => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                                             i_prof      => i_prof,
                                                                                                                             i_timestamp => i_end_date,
                                                                                                                             i_timezone  => NULL),
                                                                      o_order_recurr_desc   => l_plan_desc,
                                                                      o_order_recurr_option => l_order_recurr_option,
                                                                      o_start_date          => l_start_date,
                                                                      o_occurrences         => l_occurrences,
                                                                      o_duration            => l_duration,
                                                                      o_unit_meas_duration  => l_unit_meas_duration,
                                                                      o_end_date            => l_end_date,
                                                                      o_flg_end_by_editable => l_flg_end_by_editable,
                                                                      o_error               => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
    
        -- set a temporary order recurrence plan as definitive (final status)
        IF NOT pk_order_recurrence_core.set_order_recurr_plan(i_lang                    => i_lang,
                                                              i_prof                    => i_prof,
                                                              i_order_recurr_plan       => l_created_order_recurr_plan,
                                                              o_order_recurr_option     => l_order_recurr_option,
                                                              o_final_order_recurr_plan => l_final_order_recurr_plan,
                                                              o_error                   => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- assign output variables
        o_order_recurr_plan := l_final_order_recurr_plan;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_N_SET_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END create_order_recurr_plan_api;

    FUNCTION get_recurr_order_option
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN NUMBER IS
        l_ret order_recurr_plan.id_order_recurr_option%TYPE;
    BEGIN
        l_ret := pk_order_recurrence_core.get_recurr_order_option(i_lang              => i_lang,
                                                                  i_prof              => i_prof,
                                                                  i_order_recurr_plan => i_order_recurr_plan);
        RETURN l_ret;
    
    END get_recurr_order_option;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_order_recurrence_api_db;
/
