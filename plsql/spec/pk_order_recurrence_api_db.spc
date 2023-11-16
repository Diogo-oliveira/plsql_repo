/*-- Last Change Revision: $Rev: 2028821 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_order_recurrence_api_db IS

    -- purpose: order recurrence api database package

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN t_tbl_order_recurr_plan;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN t_recurr_plan_info_rec;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION get_recurr_order_option
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN NUMBER;

    -- logging variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_error         VARCHAR2(4000);

END pk_order_recurrence_api_db;
/
