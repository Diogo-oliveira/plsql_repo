/*-- Last Change Revision: $Rev: 2028823 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_order_recurrence_core IS

    -- purpose: order recurrence core database package

    -- order plan status
    g_plan_status_temp       CONSTANT VARCHAR2(1 CHAR) := 'T'; -- temporary plan (still under edition)
    g_plan_status_final      CONSTANT VARCHAR2(1 CHAR) := 'F'; -- finished (order already requested with this plan)
    g_plan_status_predefined CONSTANT VARCHAR2(1 CHAR) := 'P'; -- predefined (used in personal settings area)

    -- application context
    g_context_settings CONSTANT VARCHAR2(1 CHAR) := 'S'; -- settings context
    g_context_patient  CONSTANT VARCHAR2(1 CHAR) := 'P'; -- patient context

    /********************************************************************************************
    * get timestamp truncated to minutes (seconds part will be zero)
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_timestamp            timestamp to truncate
    *
    * @return      tsltz                  timestamp truncated to minutes
    *
    * @author                             Carlos Loureiro
    * @since                              07-DEC-2011
    ********************************************************************************************/
    FUNCTION trunc_timestamp_to_minutes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * get order plan executions based in supplied timestamp intervals
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_order_plan               the order recurrence plan id
    * @param       i_plan_start_date          the order start interval execution plan
    * @param       i_plan_end_date            the order end interval execution plan
    * @param       i_proc_from_day            process recurrence from this timestamp (if defined)
    * @param       i_proc_from_exec_nr        process recurrence from this execution number (if defined)
    * @param       i_flg_validate_proc_from   enable/disable "proc_from" arguments validation
    * @param       o_order_plan               table collection with the execution plan for the given interval
    * @param       o_last_exec_reached        flag that indicates if the last execution was processed for given plan
    * @param       o_error                    error structure for exception handling
    *
    * @return      boolean                    true on success, otherwise false
    *
    * @value       o_last_exec_reached        {*} 'Y' last execution was processed in this function's plan interval
    *                                         {*} 'N' last execution wasn't processed in this function's plan interval
    *
    * @author                                 Carlos Loureiro
    * @since                                  07-APR-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_plan             IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_plan_start_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_plan_end_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_proc_from_day          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_proc_from_exec_nr      IN PLS_INTEGER DEFAULT NULL,
        i_flg_validate_proc_from IN VARCHAR2 DEFAULT 'Y',
        o_order_plan             OUT t_tbl_order_recurr_plan,
        o_last_exec_reached      OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_recurr_plan_proc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_plan             IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_plan_start_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_plan_end_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_proc_from_day          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_proc_from_exec_nr      IN PLS_INTEGER DEFAULT NULL,
        i_flg_validate_proc_from IN VARCHAR2 DEFAULT 'Y',
        o_order_plan             OUT t_tbl_order_recurr_plan,
        o_last_exec_reached      OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get order recurrence instructions
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_plan           the order recurrence plan
    * @param       o_order_recurr_desc    order recurrence description
    * @param       o_order_recurr_option  order recurrence option id
    * @param       o_start_date           the calculated order start date
    * @param       o_ocurrences           the number of occurrences considered in this plan
    * @param       o_duration             the duration considered in this plan
    * @param       o_unit_meas_duration   the duration unit measure considered in this plan
    * @param       o_end_date             the calculated order plan end date
    * @param       o_flg_end_by_editable  flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              20-APR-2011
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
        o_end_date            OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @since                                    20-APR-2011
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
    * get day from given timestamp (truncate the timestamp to only provide YYYY-MM-DD information)
    *
    * @param       i_timestamp                     regular timestamp
    *
    * @return      timestamp with time zone        truncated timestamp to only provide day info
    *                                              (with professional's institution time zone)
    *
    * @author                                      Tiago Silva
    * @since                                       18-MAY-2011
    ********************************************************************************************/
    FUNCTION get_timestamp_day_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    /********************************************************************************************
    * add an offset quantity to timestamp, according to specified unit
    *
    * @param       i_offset                  number to use as an offset
    * @param       i_timestamp               timestamp to add the offset
    * @param       i_unit                    offset's unit (minute, hour, day, week, month, year)
    *
    * @return      timestamp with time zone  the sum of timestamp plus offset
    *
    * @author                                Carlos Loureiro
    * @since                                 07-APR-2011
    ********************************************************************************************/
    FUNCTION add_offset_to_tstz
    (
        i_offset    IN NUMBER,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_unit      IN unit_measure.id_unit_measure%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

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
    * @since                                  29-APR-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_option_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get order recurrence plan frequency field description
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_order_recurr_plan        order recurrence plan id
    * @param       o_error                    error structure for exception handling
    *
    * @return      varchar2                   order recurrence plan frequency field description
    *
    * @author                                 Carlos Loureiro
    * @since                                  12-MAY-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_pfreq_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN VARCHAR2;

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
    * get predefined time schedules
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_area      order recurrence area internal name
    * @param       o_predef_time_schedules  cursor with the predefined time schedules
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                20-APR-2011
    ********************************************************************************************/
    FUNCTION get_predefined_time_schedules
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_order_recurr_area     IN order_recurr_area.internal_name%TYPE,
        o_predef_time_schedules OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_predefined_time_schedules
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_area IN order_recurr_area.internal_name%TYPE
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * get most frequent recurrences
    *
    * @param       i_lang                  preferred language id
    * @param       i_prof                  professional structure
    * @param       i_order_recurr_area     order recurrence area internal name
    * @param       o_order_recurr_options  cursor with the most frequent order recurrence options
    * @param       o_error                 error structure for exception handling
    *
    * @return      boolean                 true on success, otherwise false
    *
    * @author                              Tiago Silva
    * @since                               20-APR-2011
    ********************************************************************************************/
    FUNCTION get_most_frequent_recurrences
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_recurr_area    IN order_recurr_area.internal_name%TYPE,
        o_order_recurr_options OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_most_frequent_recurrences
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_area IN order_recurr_area.internal_name%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_order_recurr_plan_end
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_domain      IN VARCHAR2,
        i_flg_context IN VARCHAR2,
        o_domains     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_recurr_plan_end
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_domain      IN VARCHAR2,
        i_flg_context IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * create a temporary or predefined order recurrence plan
    *
    * @param       i_lang                             preferred language id
    * @param       i_prof                             professional structure
    * @param       i_order_recurr_area                order recurrence area internal name
    * @param       i_order_recurr_option              order recurrence option id (optional)
    * @param       i_flg_include_start_dt_in_plan     flag that indicates if start date must be included in the plan or not (optional)
    * @param       i_flg_status                       flag that indicates order recurrence plan status (optional)
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
    * @value       i_flg_status                       {*} 'T' temporay plan
    *                                                 {*} 'P' predefined plan
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
        i_flg_status                   IN VARCHAR2 DEFAULT g_plan_status_temp,
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
    * copy an existing temporary order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan_from existing order recurrence plan to copy from
    * @param       i_flg_force_temp_plan    duplicated plan can be forced as temporary or not
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    default order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan      new order recurrence plan id for created copy
    * @param       o_error                  error structure for exception handling
    *
    * @value       i_flg_force_temp_plan    {*} 'Y' duplicated plan shall be temporary
    *                                       {*} 'N' duplicate plan assigning original status value
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Carlos Loureiro
    * @since                                29-APR-2011
    ********************************************************************************************/
    FUNCTION copy_order_recurr_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_recurr_plan_from IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_force_temp_plan    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_order_recurr_desc      OUT VARCHAR2,
        o_order_recurr_option    OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date             OUT order_recurr_plan.start_date%TYPE,
        o_occurrences            OUT order_recurr_plan.occurrences%TYPE,
        o_duration               OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration     OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date               OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable    OUT VARCHAR2,
        o_order_recurr_plan      OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                  OUT t_error_out
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
        o_end_date               OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable    OUT VARCHAR2,
        o_order_recurr_plan      OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * edit from existing order recurrence plan, with start date and option adjustments (perform a copy from)
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_area      order recurrence area internal name
    * @param       i_order_recurr_option    desired plan recurrence option
    * @param       i_start_date             desired start date plan
    * @param       i_occurrences            number of occurrences defined by the user
    * @param       i_duration               duration defined by the user
    * @param       i_unit_meas_duration     duration unit measure defined by the user
    * @param       i_end_date               order plan end date defined by the user
    * @param       i_order_recurr_plan_from order recurrence plan to copy from
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    default order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_order_recurr_plan      new order recurrence plan id for created copy
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @author                               Carlos Loureiro
    * @since                                26-OCT-2011
    ********************************************************************************************/
    FUNCTION edit_order_recurr_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_recurr_area      IN order_recurr_area.internal_name%TYPE,
        i_order_recurr_option    IN order_recurr_plan.id_order_recurr_option%TYPE DEFAULT NULL,
        i_start_date             IN order_recurr_plan.start_date%TYPE DEFAULT current_timestamp,
        i_occurrences            IN order_recurr_plan.occurrences%TYPE,
        i_duration               IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration     IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date               IN order_recurr_plan.end_date%TYPE,
        i_order_recurr_plan_from IN order_recurr_plan.id_order_recurr_plan%TYPE,
        o_order_recurr_desc      OUT VARCHAR2,
        o_order_recurr_option    OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date             OUT order_recurr_plan.start_date%TYPE,
        o_occurrences            OUT order_recurr_plan.occurrences%TYPE,
        o_duration               OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration     OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date               OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable    OUT VARCHAR2,
        o_order_recurr_plan      OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set a new order recurrence option for a given order recurrence plan
    *
    * @param       i_lang                             preferred language id
    * @param       i_prof                             professional structure
    * @param       i_order_recurr_plan                order recurrence plan id
    * @param       i_order_recurr_option              order recurrence option id
    * @param       i_order_recurr_area                order_recurrence area id
    * @param       i_flg_new_order_recurr_plan        flag that indicates if this is a new order recurrence plan or not
    * @param       i_flg_include_start_dt_in_plan     flag that indicates if start date must be included in the plan or not (optional)
    * @param       i_flg_status                       flag that indicates order recurrence plan status (optional)
    * @param       o_order_recurr_desc                order recurrence description
    * @param       o_start_date                       calculated order start date
    * @param       o_ocurrences                       number of occurrences considered in this plan
    * @param       o_duration                         duration considered in this plan
    * @param       o_unit_meas_duration               duration unit measure considered in this plan
    * @param       o_end_date                         calculated order plan end date
    * @param       o_flg_end_by_editable              flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_error                            error structure for exception handling
    *
    * @value       i_flg_include_start_dt_in_plan     {*} 'Y' include start date in the execution plan
    *                                                 {*} 'N' not include start date in the execution plan
    *
    * @value       i_flg_status                       {*} 'T' temporay plan
    *                                                 {*} 'P' predefined plan
    *
    * @value       o_flg_end_by_editable              {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                                 {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                            true on success, otherwise false
    *
    * @author                                         Tiago Silva
    * @since                                          26-APR-2011
    ********************************************************************************************/
    FUNCTION set_order_recurr_option
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof                         IN profissional,
        i_order_recurr_plan            IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_order_recurr_option          IN order_recurr_option.id_order_recurr_option%TYPE,
        i_order_recurr_area            IN VARCHAR2 DEFAULT NULL,
        i_flg_new_order_recurr_plan    IN VARCHAR2 DEFAULT 'N',
        i_flg_include_start_dt_in_plan IN VARCHAR2 DEFAULT 'N',
        i_flg_status                   IN VARCHAR2 DEFAULT NULL,
        o_order_recurr_desc            OUT VARCHAR2,
        o_start_date                   OUT order_recurr_plan.start_date%TYPE,
        o_occurrences                  OUT order_recurr_plan.occurrences%TYPE,
        o_duration                     OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration           OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                     OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable          OUT VARCHAR2,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set new order recurrence instructions for a given order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       i_start_date             order start date defined by the user
    * @param       i_occurrences            number of occurrences defined by the user
    * @param       i_duration               duration defined by the user
    * @param       i_unit_meas_duration     duration unit measure defined by the user
    * @param       i_end_date               order plan end date defined by the user
    * @param       o_order_recurr_desc      order recurrence description
    * @param       o_order_recurr_option    order recurrence option id
    * @param       o_start_date             calculated order start date
    * @param       o_ocurrences             number of occurrences considered in this plan
    * @param       o_duration               duration considered in this plan
    * @param       o_unit_meas_duration     duration unit measure considered in this plan
    * @param       o_end_date               calculated order plan end date
    * @param       o_flg_end_by_editable    flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_error                  error structure for exception handling
    *
    * @value       o_flg_end_by_editable    {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                       {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                26-APR-2011
    ********************************************************************************************/
    FUNCTION set_order_recurr_instructions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_plan   IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_start_date          IN order_recurr_plan.start_date%TYPE,
        i_occurrences         IN order_recurr_plan.occurrences%TYPE,
        i_duration            IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration  IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date            IN order_recurr_plan.end_date%TYPE,
        o_order_recurr_desc   OUT VARCHAR2,
        o_order_recurr_option OUT order_recurr_plan.id_order_recurr_option%TYPE,
        o_start_date          OUT order_recurr_plan.start_date%TYPE,
        o_occurrences         OUT order_recurr_plan.occurrences%TYPE,
        o_duration            OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration  OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date            OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set a new order recurrence option for a given order recurrence plan
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plan              order recurrence plan id
    * @param       i_regular_interval               regular interval
    * @param       i_unit_meas_regular_interval     regular interval unit measure
    * @param       i_daily_executions               number of daily executions
    * @param       i_predef_time_sched              predefined time schedules ids
    * @param       i_exec_time_parent_option        array of execution time parent options (predefined time schedules options)
    * @param       i_exec_time_option               array of execution time options
    * @param       i_exec_time                      array of exec times
    * @param       i_exec_time_offset               array of exec time offsets
    * @param       i_unit_meas_exec_time_offset     array of exec time offsets unit measures
    * @param       i_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       i_repeat_every                   recurrence frequency
    * @param       i_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       i_start_date                     order start date defined by the user
    * @param       i_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       i_occurrences                    number of occurrences
    * @param       i_duration                       duration
    * @param       i_unit_meas_duration             duration unit measure
    * @param       i_end_date                       order end date
    * @param       i_flg_week_day                   array of week day options
    * @param       i_flg_week                       array of week options
    * @param       i_month_day                      array of month day options
    * @param       i_month                          array of month options
    * @param       o_order_recurr_desc              order recurrence description
    * @param       o_start_date                     calculated order start date
    * @param       o_ocurrences                     number of occurrences considered in this plan
    * @param       o_duration                       duration considered in this plan
    * @param       o_unit_meas_duration             duration unit measure considered in this plan
    * @param       o_end_date                       calculated order plan end date
    * @param       o_flg_end_by_editable            flag that indicates if "executions", "duration" and "end date" fields must be editable or not
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       i_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       i_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       i_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       i_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_end_by_editable            {*} 'Y' "executions", "duration" and "end date" fields must be editable
    *                                               {*} 'N' "executions", "duration" and "end date" fields must be not editable
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        26-APR-2011
    ********************************************************************************************/
    FUNCTION set_other_order_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_regular_interval           IN order_recurr_plan.regular_interval%TYPE,
        i_unit_meas_regular_interval IN order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        i_daily_executions           IN order_recurr_plan.daily_executions%TYPE,
        i_predef_time_sched          IN table_number,
        i_exec_time_parent_option    IN table_number,
        i_exec_time_option           IN table_number,
        i_exec_time                  IN table_varchar,
        i_exec_time_offset           IN table_number,
        i_unit_meas_exec_time_offset IN table_number,
        i_flg_recurr_pattern         IN order_recurr_plan.flg_recurr_pattern%TYPE,
        i_repeat_every               IN order_recurr_plan.repeat_every%TYPE,
        i_flg_repeat_by              IN order_recurr_plan.flg_repeat_by%TYPE,
        i_start_date                 IN order_recurr_plan.start_date%TYPE,
        i_flg_end_by                 IN order_recurr_plan.flg_end_by%TYPE,
        i_occurrences                IN order_recurr_plan.occurrences%TYPE,
        i_duration                   IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration         IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date                   IN order_recurr_plan.end_date%TYPE,
        i_flg_week_day               IN table_number,
        i_flg_week                   IN table_number,
        i_month_day                  IN table_number,
        i_month                      IN table_number,
        o_order_recurr_desc          OUT VARCHAR2,
        o_start_date                 OUT order_recurr_plan.start_date%TYPE,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                   OUT order_recurr_plan.end_date%TYPE,
        o_flg_end_by_editable        OUT VARCHAR2,
        o_error                      OUT t_error_out
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
    * cancel a temporary or predefined order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       i_flg_persist_plan       flag that indicates if ordear recurrence plan id should persist or not
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
        i_flg_persist_plan  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get a formated execution time based in the given interval and offset values
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_exec_time              execution time
    *
    * @return      varchar2                 formated execution time
    *
    * @author                               Carlos Loureiro
    * @since                                29-APR-2011
    ********************************************************************************************/
    FUNCTION get_exec_time_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exec_time IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

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
    * encode execution time (to be used by the Flash layer)
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_exec_time              execution time
    *
    * @return      varchar2                 encoded execution time
    *
    * @author                               Tiago Silva
    * @since                                04-MAY-2011
    ********************************************************************************************/
    FUNCTION encode_exec_time
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exec_time IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get other order recurrence option data
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plan              order recurrence plan id
    * @param       i_flg_context                    flag that indicates the application context where this function is being called
    * @param       o_regular_interval               regular interval
    * @param       o_unit_meas_regular_interval     regular interval unit measure
    * @param       o_daily_executions               number of daily executions
    * @param       o_predef_time_sched              predefined time schedules ids
    * @param       o_exec_times                     cursor of execution times
    * @param       o_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       o_repeat_every                   recurrence frequency
    * @param       o_unit_meas_repeat_every         recurrence frequency unit measure
    * @param       o_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       o_start_date                     order start date defined by the user
    * @param       o_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       o_occurrences                    number of occurrences
    * @param       o_duration                       duration
    * @param       o_unit_meas_duration             duration unit measure
    * @param       o_end_date                       order end date
    * @param       o_flg_week_day                   array of week day options
    * @param       o_flg_week                       array of week options
    * @param       o_month_day                      array of month day options
    * @param       o_month                          array of month options
    * @param       o_flg_regular_interval_edit      flag that indicates if regular interval field must be editable or not
    * @param       o_flg_daily_executions_edit      flag that indicates if daily executions field must be editable or not
    * @param       o_flg_predef_time_sched_edit     flag that indicates if predefined time schedules field must be editable or not
    * @param       o_flg_exec_time_edit             flag that indicates if execution times fields must be editable or not
    * @param       o_flg_repeat_every_edit          flag that indicates if "repeat every" field must be editable or not
    * @param       o_flg_repeat_by_edit             flag that indicates if "repeat by" field must be editable or not
    * @param       o_flg_start_date_edit            flag that indicates if start date field must be editable or not
    * @param       o_flg_end_by_edit                flag that indicates if "end by" field must be editable or not
    * @param       o_flg_end_after_edit             flag that indicates if "end after" field must be editable or not
    * @param       o_flg_week_day_edit              flag that indicates if "week day" field must be editable or not
    * @param       o_flg_week_edit                  flag that indicates if "week" field must be editable or not
    * @param       o_flg_month_day_edit             flag that indicates if "month day" field must editable or not
    * @param       o_flg_month_edit                 flag that indicates if "month" field must editable or not
    * @param       o_flg_ok_avail                   flag that indicates if ok button must be available or not
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_context                    {*} 'S' settings context
    *                                               {*} 'P' patient context
    *
    * @value       o_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       o_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       o_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       o_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       o_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_regular_interval_edit      {*} 'Y' regular interval field must be editable
    *                                               {*} 'N' regular interval field must be not editable
    *
    * @value       o_flg_daily_executions_edit      {*} 'Y' daily executions field must be editable
    *                                               {*} 'N' daily executions field must be not editable
    *
    * @value       o_flg_predef_time_sched_edit     {*} 'Y' predefined time schedules field field must be editable
    *                                               {*} 'N' predefined time schedules field field must be not editable
    *
    * @value       o_flg_exec_time_edit             {*} 'Y' execution times fields must be editable
    *                                               {*} 'N' execution times fields must be not editable
    *
    * @value       o_flg_repeat_every_edit          {*} 'Y' "repeat every" field must be editable
    *                                               {*} 'N' "repeat every" field must be not editable
    *
    * @value       o_flg_repeat_by_edit             {*} 'Y' "repeat by" field must be editable
    *                                               {*} 'N' "repeat by" field must be not editable
    *
    * @value       o_flg_start_date_edit            {*} 'Y' start date field must be editable
    *                                               {*} 'N' start date field must be not editable
    *
    * @value       o_flg_end_by_edit                {*} 'Y' "end by" field must be editable
    *                                               {*} 'N' "end by" field must be not editable
    *
    * @value       o_flg_end_after_edit             {*} 'Y' "end after" field must be editable
    *                                               {*} 'N' "end after" field must be not editable
    *
    * @value       o_flg_week_day_edit              {*} 'Y' "week day" field must be editable
    *                                               {*} 'N' "week day" field must be not editable
    *
    * @value       o_flg_week_edit                  {*} 'Y' "week" field must be editable
    *                                               {*} 'N' "week" field must be not editable
    *
    * @value       o_flg_month_day_edit             {*} 'Y' "month day" field must be editable
    *                                               {*} 'N' "month day" field must be not editable
    *
    * @value       o_flg_month_edit                 {*} 'Y' "month" field must be editable
    *                                               {*} 'N' "month" field must be not editable
    *
    * @value       o_flg_ok_avail                   {*} 'Y' ok button must be available
    *                                               {*} 'N' ok bytton must be not available
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        29-APR-2011
    ********************************************************************************************/
    FUNCTION get_other_order_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_context                IN VARCHAR2 DEFAULT g_context_patient,
        o_regular_interval           OUT order_recurr_plan.regular_interval%TYPE,
        o_unit_meas_regular_interval OUT order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        o_daily_executions           OUT order_recurr_plan.daily_executions%TYPE,
        o_predef_time_sched          OUT table_number,
        o_exec_times                 OUT t_tbl_recurr_exec_times,
        o_flg_recurr_pattern         OUT order_recurr_plan.flg_recurr_pattern%TYPE,
        o_repeat_every               OUT order_recurr_plan.repeat_every%TYPE,
        o_unit_meas_repeat_every     OUT unit_measure.id_unit_measure%TYPE,
        o_flg_repeat_by              OUT order_recurr_plan.flg_repeat_by%TYPE,
        o_start_date                 OUT order_recurr_plan.start_date%TYPE,
        o_flg_end_by                 OUT order_recurr_plan.flg_end_by%TYPE,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                   OUT order_recurr_plan.end_date%TYPE,
        o_flg_week_day               OUT table_number,
        o_flg_week                   OUT table_number,
        o_month_day                  OUT table_number,
        o_month                      OUT table_number,
        o_flg_regular_interval_edit  OUT VARCHAR2,
        o_flg_daily_executions_edit  OUT VARCHAR2,
        o_flg_predef_time_sched_edit OUT VARCHAR2,
        o_flg_exec_time_edit         OUT VARCHAR2,
        o_flg_repeat_every_edit      OUT VARCHAR2,
        o_flg_repeat_by_edit         OUT VARCHAR2,
        o_flg_start_date_edit        OUT VARCHAR2,
        o_flg_end_by_edit            OUT VARCHAR2,
        o_flg_end_after_edit         OUT VARCHAR2,
        o_flg_week_day_edit          OUT VARCHAR2,
        o_flg_week_edit              OUT VARCHAR2,
        o_flg_month_day_edit         OUT VARCHAR2,
        o_flg_month_edit             OUT VARCHAR2,
        o_flg_ok_avail               OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check other order recurrence option data
    *
    * @param       i_lang                           preferred language id
    * @param       i_prof                           professional structure
    * @param       i_order_recurr_plan              order recurrence plan id
    * @param       i_edit_field_name                name of field edited by the user
    * @param       i_regular_interval               regular interval
    * @param       i_unit_meas_regular_interval     regular interval unit measure
    * @param       i_daily_executions               number of daily executions
    * @param       i_predef_time_sched              predefined time schedules ids
    * @param       i_exec_time_parent_option        array of execution time parent options (predefined time schedules options)
    * @param       i_exec_time_option               array of execution time options
    * @param       i_exec_time                      array of exec times
    * @param       i_exec_time_offset               array of exec time offsets
    * @param       i_unit_meas_exec_time_offset     array of exec time offsets unit measures
    * @param       i_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       i_repeat_every                   recurrence frequency
    * @param       i_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       i_start_date                     order start date defined by the user
    * @param       i_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       i_occurrences                    number of occurrences
    * @param       i_duration                       duration
    * @param       i_unit_meas_duration             duration unit measure
    * @param       i_end_date                       order end date
    * @param       i_flg_week_day                   array of week day options
    * @param       i_flg_week                       array of week options
    * @param       i_flg_context                    flag that indicates the application context where this function is being called
    * @param       o_regular_interval               regular interval
    * @param       o_unit_meas_regular_interval     regular interval unit measure
    * @param       o_daily_executions               number of daily executions
    * @param       o_predef_time_sched              predefined time schedules ids
    * @param       o_exec_times                     cursor of execution times
    * @param       o_flg_recurr_pattern             flag that indicates the recurrence pattern
    * @param       o_repeat_every                   recurrence frequency
    * @param       o_unit_meas_repeat_every         recurrence frequency unit measure
    * @param       o_flg_repeat_by                  flag that indicates if the recurrence pattern must be repeated by month days or week days
    * @param       o_start_date                     order start date defined by the user
    * @param       o_flg_end_by                     flag that indicates which parameter must be considered to calculate the recurrence end date
    * @param       o_occurrences                    number of occurrences
    * @param       o_duration                       duration
    * @param       o_unit_meas_duration             duration unit measure
    * @param       o_end_date                       order end date
    * @param       o_flg_week_day                   array of week day options
    * @param       o_flg_week                       array of week options
    * @param       o_month_day                      array of month day options
    * @param       o_month                          array of month options
    * @param       o_flg_regular_interval_edit      flag that indicates if regular interval field must be editable or not
    * @param       o_flg_daily_executions_edit      flag that indicates if daily executions field must be editable or not
    * @param       o_flg_predef_time_sched_edit     flag that indicates if predefined time schedules field must be editable or not
    * @param       o_flg_exec_time_edit             flag that indicates if execution times fields must be editable or not
    * @param       o_flg_repeat_every_edit          flag that indicates if "repeat every" field must be editable or not
    * @param       o_flg_repeat_by_edit             flag that indicates if "repeat by" field must be editable or not
    * @param       o_flg_start_date_edit            flag that indicates if start date field must be editable or not
    * @param       o_flg_end_by_edit                flag that indicates if "end by" field must be editable or not
    * @param       o_flg_end_after_edit             flag that indicates if "end after" field must be editable or not
    * @param       o_flg_week_day_edit              flag that indicates if "week day" field must be editable or not
    * @param       o_flg_week_edit                  flag that indicates if "week" field must be editable or not
    * @param       o_flg_month_day_edit             flag that indicates if "month day" field must editable or not
    * @param       o_flg_month_edit                 flag that indicates if "month" field must editable or not
    * @param       o_flg_ok_avail                   flag that indicates if ok button must be available or not
    * @param       o_error                          error structure for exception handling
    *
    * @value       i_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       i_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       i_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       i_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       i_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       i_flg_context                    {*} 'S' settings context
    *                                               {*} 'P' patient context
    *
    * @value       o_flg_recurr_pattern             {*} '0' without recurrence
    *                                               {*} 'D' daily
    *                                               {*} 'W' weekly
    *                                               {*} 'M' monthly
    *                                               {*} 'Y' yearly
    *
    * @value       o_flg_recurr_pattern             {*} 'M' month days
    *                                               {*} 'W' week days
    *
    * @value       o_flg_end_by                     {*} 'D' date
    *                                               {*} 'W' without end date
    *                                               {*} 'N' number of executions
    *                                               {*} 'L' duration
    *
    * @value       o_flg_week_day                   {*} 1 Sunday
    *                                               {*} 2 Monday
    *                                               {*} 3 Tuesday
    *                                               {*} 4 Wednesday
    *                                               {*} 5 Thursday
    *                                               {*} 6 Friday
    *                                               {*} 7 Saturday
    *
    * @value       o_flg_week                       {*} 1 first
    *                                               {*} 2 second
    *                                               {*} 3 third
    *                                               {*} 4 fourth
    *                                               {*} 5 last
    *
    * @value       o_flg_regular_interval_edit      {*} 'Y' regular interval field must be editable
    *                                               {*} 'N' regular interval field must be not editable
    *
    * @value       o_flg_daily_executions_edit      {*} 'Y' daily executions field must be editable
    *                                               {*} 'N' daily executions field must be not editable
    *
    * @value       o_flg_predef_time_sched_edit     {*} 'Y' predefined time schedules field field must be editable
    *                                               {*} 'N' predefined time schedules field field must be not editable
    *
    * @value       o_flg_exec_time_edit             {*} 'Y' execution times fields must be editable
    *                                               {*} 'N' execution times fields must be not editable
    *
    * @value       o_flg_repeat_every_edit          {*} 'Y' "repeat every" field must be editable
    *                                               {*} 'N' "repeat every" field must be not editable
    *
    * @value       o_flg_repeat_by_edit             {*} 'Y' "repeat by" field must be editable
    *                                               {*} 'N' "repeat by" field must be not editable
    *
    * @value       o_flg_start_date_edit            {*} 'Y' start date field must be editable
    *                                               {*} 'N' start date field must be not editable
    *
    * @value       o_flg_end_by_edit                {*} 'Y' "end by" field must be editable
    *                                               {*} 'N' "end by" field must be not editable
    *
    * @value       o_flg_end_after_edit             {*} 'Y' "end after" field must be editable
    *                                               {*} 'N' "end after" field must be not editable
    *
    * @value       o_flg_week_day_edit              {*} 'Y' "week day" field must be editable
    *                                               {*} 'N' "week day" field must be not editable
    *
    * @value       o_flg_week_edit                  {*} 'Y' "week" field must be editable
    *                                               {*} 'N' "week" field must be not editable
    *
    * @value       o_flg_month_day_edit             {*} 'Y' "month day" field must be editable
    *                                               {*} 'N' "month day" field must be not editable
    *
    * @value       o_flg_month_edit                 {*} 'Y' "month" field must be editable
    *                                               {*} 'N' "month" field must be not editable
    *
    * @value       o_flg_ok_avail                   {*} 'Y' ok button must be available
    *                                               {*} 'N' ok bytton must be not available
    *
    * @return      boolean                          true on success, otherwise false
    *
    * @author                                       Tiago Silva
    * @since                                        29-APR-2011
    ********************************************************************************************/
    FUNCTION check_other_recurr_option
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_order_recurr_plan          IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_edit_field_name            IN VARCHAR2,
        i_regular_interval           IN order_recurr_plan.regular_interval%TYPE,
        i_unit_meas_regular_interval IN order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        i_daily_executions           IN order_recurr_plan.daily_executions%TYPE,
        i_predef_time_sched          IN table_number,
        i_exec_time_parent_option    IN table_number,
        i_exec_time_option           IN table_number,
        i_exec_time                  IN table_varchar,
        i_exec_time_offset           IN table_number,
        i_unit_meas_exec_time_offset IN table_number,
        i_flg_recurr_pattern         IN order_recurr_plan.flg_recurr_pattern%TYPE,
        i_repeat_every               IN order_recurr_plan.repeat_every%TYPE,
        i_flg_repeat_by              IN order_recurr_plan.flg_repeat_by%TYPE,
        i_start_date                 IN order_recurr_plan.start_date%TYPE,
        i_flg_end_by                 IN order_recurr_plan.flg_end_by%TYPE,
        i_occurrences                IN order_recurr_plan.occurrences%TYPE,
        i_duration                   IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration         IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_end_date                   IN order_recurr_plan.end_date%TYPE,
        i_flg_week_day               IN table_number,
        i_flg_week                   IN table_number,
        i_month_day                  IN table_number,
        i_month                      IN table_number,
        i_flg_context                IN VARCHAR2 DEFAULT g_context_patient,
        o_regular_interval           OUT order_recurr_plan.regular_interval%TYPE,
        o_unit_meas_regular_interval OUT order_recurr_plan.id_unit_meas_regular_interval%TYPE,
        o_daily_executions           OUT order_recurr_plan.daily_executions%TYPE,
        o_predef_time_sched          OUT table_number,
        o_exec_times                 OUT t_tbl_recurr_exec_times,
        o_flg_recurr_pattern         OUT order_recurr_plan.flg_recurr_pattern%TYPE,
        o_repeat_every               OUT order_recurr_plan.repeat_every%TYPE,
        o_unit_meas_repeat_every     OUT unit_measure.id_unit_measure%TYPE,
        o_flg_repeat_by              OUT order_recurr_plan.flg_repeat_by%TYPE,
        o_start_date                 OUT order_recurr_plan.start_date%TYPE,
        o_flg_end_by                 OUT order_recurr_plan.flg_end_by%TYPE,
        o_occurrences                OUT order_recurr_plan.occurrences%TYPE,
        o_duration                   OUT order_recurr_plan.duration%TYPE,
        o_unit_meas_duration         OUT order_recurr_plan.id_unit_meas_duration%TYPE,
        o_end_date                   OUT order_recurr_plan.end_date%TYPE,
        o_flg_week_day               OUT table_number,
        o_flg_week                   OUT table_number,
        o_month_day                  OUT table_number,
        o_month                      OUT table_number,
        o_flg_regular_interval_edit  OUT VARCHAR2,
        o_flg_daily_executions_edit  OUT VARCHAR2,
        o_flg_predef_time_sched_edit OUT VARCHAR2,
        o_flg_exec_time_edit         OUT VARCHAR2,
        o_flg_repeat_every_edit      OUT VARCHAR2,
        o_flg_repeat_by_edit         OUT VARCHAR2,
        o_flg_start_date_edit        OUT VARCHAR2,
        o_flg_end_by_edit            OUT VARCHAR2,
        o_flg_end_after_edit         OUT VARCHAR2,
        o_flg_week_day_edit          OUT VARCHAR2,
        o_flg_week_edit              OUT VARCHAR2,
        o_flg_month_day_edit         OUT VARCHAR2,
        o_flg_month_edit             OUT VARCHAR2,
        o_flg_ok_avail               OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get execution time based in the given interval and offset values
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_exec_time              interval in day to second format
    * @param       i_exec_time_offset       offset to add to the execution time
    * @param       i_exec_time_offset_unit  offset unit measure id
    *
    * @return      interval day to second   execution time in interval day to second format
    *
    * @author                               Carlos Loureiro
    * @since                                04-MAY-2011
    ********************************************************************************************/
    FUNCTION decode_exec_time
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_exec_time             IN VARCHAR2,
        i_exec_time_offset      IN order_recurr_plan_time.exec_time_offset%TYPE,
        i_exec_time_offset_unit IN order_recurr_plan_time.id_unit_meas_exec_time_offset%TYPE
    ) RETURN INTERVAL DAY TO SECOND;

    /********************************************************************************************
    * get "end after" description based in recurrence end date or duration or number of occurrences
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_flg_end_by             "end by" flag
    * @param       i_end_date               end date
    * @param       i_duration               duration value
    * @param       i_unit_meas_duration     duration unit measure id
    * @param       i_occurrences            number of executions or occurrences
    *
    * @return      interval day to second   execution time in interval day to second format
    *
    * @value       i_flg_end_by             {*} 'D' date
    *                                       {*} 'W' without end date
    *                                       {*} 'N' number of executions
    *                                       {*} 'L' duration
    *
    * @author                               Carlos Loureiro
    * @since                                06-MAY-2011
    ********************************************************************************************/
    FUNCTION get_order_rec_end_after_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_end_by         IN order_recurr_plan.flg_end_by%TYPE,
        i_end_date           IN order_recurr_plan.end_date%TYPE,
        i_duration           IN order_recurr_plan.duration%TYPE,
        i_unit_meas_duration IN order_recurr_plan.id_unit_meas_duration%TYPE,
        i_occurrences        IN order_recurr_plan.occurrences%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get order recurrence plan configuration
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_area      order recurrence area id
    * @param       i_interval_name          interval name configuration
    * @param       i_id_market              market ID
    * @param       o_interval_value         interval value configuration
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Ana Monteiro
    * @since                                06-MAY-2011
    ********************************************************************************************/
    FUNCTION get_order_recurr_cfg
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_area IN order_recurr_control_cfg.id_order_recurr_area%TYPE,
        i_interval_name     IN order_recurr_control_cfg.interval_name%TYPE,
        i_id_market         IN order_recurr_control_cfg.id_market%TYPE DEFAULT NULL,
        o_interval_value    OUT order_recurr_control_cfg.interval_value%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Maintenance of order recurrence plans
    * Called by job
    *
    * @author                                      Ana Monteiro
    * @since                                       06-MAY-2011
    ********************************************************************************************/
    PROCEDURE set_order_recurr_control;

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

    FUNCTION update_recurr_control_proc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_date_plan            IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                OUT t_error_out
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

    FUNCTION get_recurr_order_option
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    -- unit measure id constants
    g_unit_measure_minute CONSTANT unit_measure.id_unit_measure%TYPE := 10374; -- unit id for minutes
    g_unit_measure_hour   CONSTANT unit_measure.id_unit_measure%TYPE := 1041; -- unit id for hours
    g_unit_measure_day    CONSTANT unit_measure.id_unit_measure%TYPE := 1039; -- unit id for days
    g_unit_measure_week   CONSTANT unit_measure.id_unit_measure%TYPE := 10375; -- unit id for weeks
    g_unit_measure_month  CONSTANT unit_measure.id_unit_measure%TYPE := 1127; -- unit id for months
    g_unit_measure_year   CONSTANT unit_measure.id_unit_measure%TYPE := 10373; -- unit id for years

    -- order recurrence pattern flags
    g_flg_recurr_pattern_none    CONSTANT VARCHAR2(1 CHAR) := '0'; -- no recurrence pattern
    g_flg_recurr_pattern_daily   CONSTANT VARCHAR2(1 CHAR) := 'D'; -- daily recurrence pattern
    g_flg_recurr_pattern_weekly  CONSTANT VARCHAR2(1 CHAR) := 'W'; -- weekly recurrence pattern
    g_flg_recurr_pattern_monthly CONSTANT VARCHAR2(1 CHAR) := 'M'; -- monthly recurrence pattern
    g_flg_recurr_pattern_yearly  CONSTANT VARCHAR2(1 CHAR) := 'Y'; -- yearly recurrence pattern

    -- order recurrence end by flags
    g_flg_end_by_no_end      CONSTANT VARCHAR2(1 CHAR) := 'W'; -- recurrence plan without end date/duration/occurrences
    g_flg_end_by_date        CONSTANT VARCHAR2(1 CHAR) := 'D'; -- recurrence plan ended by date value
    g_flg_end_by_occurrences CONSTANT VARCHAR2(1 CHAR) := 'N'; -- recurrence plan ended by number or executions
    g_flg_end_by_duration    CONSTANT VARCHAR2(1 CHAR) := 'L'; -- recurrence plan ended by duration value

    -- order recurrence repeat by flags
    g_flg_repeat_by_week_days  CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_flg_repeat_by_month_days CONSTANT VARCHAR2(1 CHAR) := 'W';

    -- order recurrence selection domain flags
    g_flg_select_dom_order_recurr CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_flg_select_dom_predef_sch   CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_flg_select_dom_both         CONSTANT VARCHAR2(1 CHAR) := 'B';

    -- order recurrence control flags
    g_flg_status_control_error     CONSTANT order_recurr_control.flg_status%TYPE := 'E'; -- error found while processing plan
    g_flg_status_control_outdated  CONSTANT order_recurr_control.flg_status%TYPE := 'O'; -- outdated plan (no order is using the plan)
    g_flg_status_control_active    CONSTANT order_recurr_control.flg_status%TYPE := 'A'; -- active plan
    g_flg_status_control_finished  CONSTANT order_recurr_control.flg_status%TYPE := 'F'; -- finished plan (no more execs to process)
    g_flg_status_control_interrupt CONSTANT order_recurr_control.flg_status%TYPE := 'I'; -- interrupted plan (this plan was edited)

    -- order recurrence control configuration names
    g_cfg_name_active_window CONSTANT order_recurr_control_cfg.interval_name%TYPE := 'ACTIVE_WINDOW';
    g_active_window_def      CONSTANT order_recurr_control_cfg.interval_value%TYPE := INTERVAL '5 00:00:00' DAY TO
                                                                                      SECOND;
    -- order recurrence areas
    g_area_lab_test          CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 1;
    g_area_image_exam        CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 2;
    g_area_other_exam        CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 3;
    g_area_pat_education     CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 4;
    g_area_adv_dir_dnar      CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 5;
    g_area_icnp              CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 6;
    g_area_nnn_noc_outcome   CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 7;
    g_area_nnn_noc_indicator CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 8;
    g_area_nnn_nic_activity  CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 9;
    g_area_procedure         CONSTANT order_recurr_area.id_order_recurr_area%TYPE := 10;

    -- order recurrence options
    g_order_recurr_option_once     CONSTANT order_recurr_option.id_order_recurr_option%TYPE := 0;
    g_order_recurr_option_other    CONSTANT order_recurr_option.id_order_recurr_option%TYPE := -1;
    g_order_recurr_option_no_sched CONSTANT order_recurr_option.id_order_recurr_option%TYPE := -2;

    -- edit fields names
    g_edit_field_regular_intervals CONSTANT VARCHAR2(30 CHAR) := 'REGULAR_INTERVALS';
    g_edit_field_daily_executions  CONSTANT VARCHAR2(30 CHAR) := 'DAILY_EXECUTIONS';
    g_edit_field_predef_sched      CONSTANT VARCHAR2(30 CHAR) := 'PREDEFINED_SCHEDULE';
    g_edit_field_exact_time        CONSTANT VARCHAR2(30 CHAR) := 'EXACT_TIME';
    g_edit_field_recurr_pattern    CONSTANT VARCHAR2(30 CHAR) := 'RECURRENCE_PATTERN';
    g_edit_field_repeat_every      CONSTANT VARCHAR2(30 CHAR) := 'REPEAT_EVERY';
    g_edit_field_repeat_by         CONSTANT VARCHAR2(30 CHAR) := 'REPEAT_BY';
    g_edit_field_on_days_of_month  CONSTANT VARCHAR2(30 CHAR) := 'ON_DAYS_OF_MONTH';
    g_edit_field_on_week_days      CONSTANT VARCHAR2(30 CHAR) := 'ON_WEEK_DAYS';
    g_edit_field_on_weeks          CONSTANT VARCHAR2(30 CHAR) := 'ON_WEEKS';
    g_edit_field_on_month          CONSTANT VARCHAR2(30 CHAR) := 'ON_MONTH';
    g_edit_field_start_date        CONSTANT VARCHAR2(30 CHAR) := 'START_DATE';
    g_edit_field_end_by            CONSTANT VARCHAR2(30 CHAR) := 'END_BY';
    g_edit_field_end_after         CONSTANT VARCHAR2(30 CHAR) := 'END_AFTER';

    -- watchdog limit
    g_watchdog_count_limit CONSTANT PLS_INTEGER := 500000;

    -- exception for dml errors
    dml_error EXCEPTION;
    PRAGMA EXCEPTION_INIT(dml_error, -24381);

    -- logging variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_error         VARCHAR2(4000);

END pk_order_recurrence_core;
/
