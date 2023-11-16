/*-- Last Change Revision: $Rev: 2027405 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_order_recurrence_core IS

    -- purpose: order recurrence core database package

    --  exceptions
    e_user_exception EXCEPTION;

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
        WITH TIME ZONE IS
        k_day_format CONSTANT pk_types.t_low_char := 'DD';
        l_tstz TIMESTAMP WITH TIME ZONE;
    BEGIN
        IF i_timestamp IS NOT NULL
        THEN
            l_tstz := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                       i_timestamp => i_timestamp,
                                                       i_format    => k_day_format);
        ELSE
            l_tstz := NULL;
        END IF;
        RETURN l_tstz;
    END get_timestamp_day_tstz;

    /********************************************************************************************
    * get difference in days/weeks/months and years between timestamps (it truncates the fraccional
    * part), based in flg_recurr_pattern value
    *
    * @param       i_flg_recurr_pattern   order recurrence pattern flag
    * @param       i_timestamp_from       timestamp from, lower than timestamp to
    * @param       i_timestamp_to         timestamp to, greater than timestamp from
    *
    * @return      boolean                true if timestamps belongs to the same day, otherwise false
    *
    * @value       i_flg_recurr_pattern   {*} '0' no recurrence pattern
    *                                     {*} 'D' daily recurrence pattern
    *                                     {*} 'W' weekly recurrence pattern
    *                                     {*} 'M' monthly recurrence pattern
    *                                     {*} 'Y' yearly recurrence pattern
    *
    * @author                             Carlos Loureiro
    * @since                              07-APR-2011
    ********************************************************************************************/
    FUNCTION get_timestamp_diff
    (
        i_flg_recurr_pattern IN order_recurr_plan.flg_recurr_pattern%TYPE,
        i_timestamp_from     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_timestamp_to       IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_ret NUMBER(6);
    BEGIN
        l_ret := CASE i_flg_recurr_pattern
                 -- daily recurrence pattern
                     WHEN g_flg_recurr_pattern_daily THEN
                      extract(DAY FROM(i_timestamp_to - i_timestamp_from))
                 -- weekly recurrence pattern
                     WHEN g_flg_recurr_pattern_weekly THEN
                      trunc(extract(DAY FROM(i_timestamp_to - i_timestamp_from)) / 7)
                 -- monthly recurrence pattern
                     WHEN g_flg_recurr_pattern_monthly THEN
                      trunc(months_between(i_timestamp_to, i_timestamp_from))
                 -- yearly recurrence pattern
                     WHEN g_flg_recurr_pattern_yearly THEN
                      trunc(months_between(i_timestamp_to, i_timestamp_from) / 12)
                 -- invalid recurrence pattern
                     ELSE
                      NULL
                 END;
        -- if result is null, then an invalid recurrence pattern flag was considered in this operation
        IF l_ret IS NULL
        THEN
            raise_application_error(-20001,
                                    'invalid value for recurrence pattern flag [' || i_flg_recurr_pattern || ']');
        END IF;
        RETURN l_ret;
    END get_timestamp_diff;

    /********************************************************************************************
    * check if both timestamps belongs to the same day
    *
    * @param       i_timestamp_1          timestamp 1
    * @param       i_timestamp_2          timestamp 2
    *
    * @return      boolean                true if timestamps belongs to the same day, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              07-APR-2011
    ********************************************************************************************/
    FUNCTION check_timestamps_same_day
    (
        i_timestamp_1 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_timestamp_2 IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN BOOLEAN IS
    BEGIN
        IF abs(trunc(extract(DAY FROM(i_timestamp_2 - i_timestamp_1)))) >= 1
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END check_timestamps_same_day;

    /********************************************************************************************
    * add an offset quantity to timestamp, according to specified unit
    *
    * @param       i_offset                  number to use as an offset
    * @param       i_timestamp               timestamp to add the offset
    * @param       i_unit                    offset's unit (minute, hour, day, week, month, year)
    *
    * @return      timestamp with local tz   the sum of timestamp plus offset
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
        WITH LOCAL TIME ZONE IS
        l_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        -- date not valid for month specified
        e_invalid_date EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_invalid_date, -01839);
    BEGIN
        IF i_offset IS NOT NULL
        THEN
            l_tstz := CASE i_unit
                      -- when i_lag is in minutes
                          WHEN g_unit_measure_minute THEN
                           i_timestamp + numtodsinterval(i_offset, 'MINUTE')
                      -- when i_lag is in hours
                          WHEN g_unit_measure_hour THEN
                           i_timestamp + numtodsinterval(i_offset, 'HOUR')
                      -- when i_lag is in days
                          WHEN g_unit_measure_day THEN
                           i_timestamp + numtodsinterval(i_offset, 'DAY')
                      -- when i_lag is in weeks
                          WHEN g_unit_measure_week THEN
                           i_timestamp + numtodsinterval(i_offset * 7, 'DAY')
                      -- when i_lag is in months
                          WHEN g_unit_measure_month THEN
                           i_timestamp + numtoyminterval(i_offset, 'MONTH')
                      -- when i_lag is in years
                          WHEN g_unit_measure_year THEN
                           i_timestamp + numtoyminterval(i_offset, 'YEAR')
                      -- else
                          ELSE
                           NULL
                      END;
            -- if result is null, then an invalid unit was considered in this operation
            IF l_tstz IS NULL
            THEN
                raise_application_error(-20001,
                                        'invalid timestamp [' || i_timestamp || '] or unit measure id [' || i_unit || ']');
            END IF;
            RETURN l_tstz;
        ELSE
            RETURN i_timestamp;
        END IF;
    
        -- exception to avoid "date not valid for month specified" error: the
        -- function will be retried with timestamp-1, to avoid leap year problem
    EXCEPTION
        WHEN e_invalid_date THEN
            g_error := 'ORA-01839 exception detected: timestamp ' || i_timestamp ||
                       ' will be shifted to 1 day before (unit measure id=' || i_unit || ')';
            pk_alertlog.log_debug(g_error, g_package_name);
            RETURN add_offset_to_tstz(i_offset => i_offset, i_timestamp => i_timestamp - 1, i_unit => i_unit);
    END add_offset_to_tstz;

    /********************************************************************************************
    * add an offset quantity to interval, according to specified unit
    *
    * @param       i_offset                  number to use as an offset
    * @param       i_interval                interval to add the offset
    * @param       i_unit                    offset's unit (minute, hour, day, week, month, year)
    *
    * @return      interval day to second    the sum of interval plus offset
    *
    * @author                                Carlos Loureiro
    * @since                                 04-MAY-2011
    ********************************************************************************************/
    FUNCTION add_offset_to_interval
    (
        i_offset   IN NUMBER,
        i_interval IN INTERVAL DAY TO SECOND,
        i_unit     IN unit_measure.id_unit_measure%TYPE
    ) RETURN INTERVAL DAY TO SECOND IS
        l_interval INTERVAL DAY(0) TO SECOND(0);
    BEGIN
        IF i_offset IS NOT NULL
        THEN
            l_interval := CASE i_unit
                          -- when i_lag is in minutes
                              WHEN g_unit_measure_minute THEN
                               i_interval + numtodsinterval(i_offset, 'MINUTE')
                          -- when i_lag is in hours
                              WHEN g_unit_measure_hour THEN
                               i_interval + numtodsinterval(i_offset, 'HOUR')
                              ELSE
                               NULL
                          END;
            -- if result is null, then an invalid unit was considered in this operation
            IF l_interval IS NULL
            THEN
                raise_application_error(-20001,
                                        'invalid interval [' || i_interval || '] or unit measure id [' || i_unit || ']');
            END IF;
            RETURN l_interval;
        ELSE
            RETURN i_interval;
        END IF;
    END add_offset_to_interval;

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
    ) RETURN VARCHAR2 IS
    BEGIN
    
        -- return formatted execution time, according to professional's environment
        RETURN pk_date_utils.dt_chr_hour_tsz(i_lang, i_exec_time, i_prof.institution, i_prof.software);
    
    END get_exec_time_desc;

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
    ) RETURN VARCHAR2 IS
    BEGIN
    
        -- return encoded execution time
        RETURN to_char(pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, i_exec_time), 'HH24MI');
    
    END encode_exec_time;

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
    ) RETURN INTERVAL DAY TO SECOND IS
        l_minute   PLS_INTEGER;
        l_hour     PLS_INTEGER;
        l_interval INTERVAL DAY(0) TO SECOND(0);
    BEGIN
    
        -- check if execution time is null
        IF i_exec_time IS NULL
        THEN
            RETURN NULL;
            -- check if execution time has the correct length
        ELSIF length(i_exec_time) = 4
        THEN
            -- parse hour and minute fields
            l_hour   := to_number(substr(i_exec_time, 1, 2));
            l_minute := to_number(substr(i_exec_time, 3, 2));
            -- check value limits
            IF l_hour BETWEEN 0 AND 23
               AND l_minute BETWEEN 0 AND 59
            THEN
                l_interval := numtodsinterval(l_hour, 'HOUR') + numtodsinterval(l_minute, 'MINUTE');
                IF i_exec_time_offset IS NOT NULL
                   AND i_exec_time_offset_unit IS NOT NULL
                THEN
                    RETURN add_offset_to_interval(i_offset   => -1 * i_exec_time_offset,
                                                  i_interval => l_interval,
                                                  i_unit     => i_exec_time_offset_unit);
                ELSE
                    RETURN l_interval;
                END IF;
            ELSE
                raise_application_error(-20001,
                                        'invalid execution time (cannot convert hour/minute value into interval)');
            END IF;
        ELSE
            raise_application_error(-20001, 'invalid execution time (hour/minute value is not in HH24MI format');
        END IF;
    
    END decode_exec_time;

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
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN pk_date_utils.get_string_tstz(i_lang,
                                             i_prof,
                                             to_char(pk_date_utils.get_timestamp_insttimezone(i_lang,
                                                                                              i_prof.institution,
                                                                                              i_timestamp),
                                                     'YYYYMMDDHH24MI') || '00',
                                             NULL);
    END trunc_timestamp_to_minutes;

    /********************************************************************************************
    * get unit measure id for defined recurrence
    *
    * @param       i_flg_recurr_pattern   flag recurrence pattern
    *
    * @return      number                 recurrence pattern unit measure id
    *
    * @author                             Carlos Loureiro
    * @since                              12-MAY-2011
    ********************************************************************************************/
    FUNCTION get_unit_meas_repeat_interval(i_flg_recurr_pattern IN order_recurr_plan.flg_recurr_pattern%TYPE) RETURN NUMBER IS
    BEGIN
        RETURN CASE i_flg_recurr_pattern WHEN g_flg_recurr_pattern_daily THEN g_unit_measure_day WHEN g_flg_recurr_pattern_weekly THEN g_unit_measure_week WHEN g_flg_recurr_pattern_monthly THEN g_unit_measure_month WHEN g_flg_recurr_pattern_yearly THEN g_unit_measure_year ELSE NULL END;
    END get_unit_meas_repeat_interval;

    /********************************************************************************************
    * set (and validate) the plan window based in supplied timestamp intervals
    *
    * @param       i_lang                         preferred language id
    * @param       io_plan_start_date             the order start interval execution plan
    * @param       io_plan_end_date               the order end interval execution plan
    * @param       i_proc_from_day                process from day (if defined)
    * @param       i_proc_from_exec_nr            process from execution number (if defined)
    * @param       i_flg_validate_proc_from       enable/disable "proc_from" arguments validation
    * @param       i_order_plan_record            the order recurrence plan record
    * @param       o_plan_exec_nr                 plan starting execution number
    * @param       o_order_start_date             order start date to consider in plan processing
    * @param       o_order_end_date               order end date
    * @param       o_error                        error structure for exception handling
    *
    * @return      boolean                        true on success, otherwise false
    *
    * @value       i_flg_validate_proc_from       {*} 'Y' validation on "proc_from" arguments will be made
    *                                             {*} 'N' validation on "proc_from" arguments will be bypassed
    *
    * @author                                     Carlos Loureiro
    * @since                                      14-APR-2011
    ********************************************************************************************/
    FUNCTION set_order_plan_interval
    (
        i_lang                   IN language.id_language%TYPE,
        io_plan_start_date       IN OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        io_plan_end_date         IN OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        i_proc_from_day          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_proc_from_exec_nr      IN PLS_INTEGER,
        i_flg_validate_proc_from IN VARCHAR2 DEFAULT 'Y',
        i_order_plan_record      IN order_recurr_plan%ROWTYPE,
        o_plan_exec_nr           OUT PLS_INTEGER,
        o_order_start_date       OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_order_date_limit       OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_plan_end_date TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- pre-processing validations
        /*IF io_plan_start_date = io_plan_end_date
        THEN
            g_error := 'start plan date cannot be the same as the end plan date (interval cannot be zero)';
            RAISE e_user_exception;
        ELSIF io_plan_start_date < i_order_plan_record.start_date
              AND i_flg_validate_proc_from = pk_alert_constant.g_yes
        THEN
            g_error := 'order start date cannot be greater than start plan interval';
            RAISE e_user_exception;
        ELSIF io_plan_end_date < io_plan_start_date
        THEN
            g_error := 'start plan interval cannot be greater than end plan interval';
            RAISE e_user_exception;
        ELSIF io_plan_start_date IS NULL
        THEN
            g_error := 'start plan interval cannot be null';
            RAISE e_user_exception;
        ELSIF (i_proc_from_day IS NOT NULL AND i_proc_from_exec_nr IS NULL)
              OR (i_proc_from_day IS NULL AND i_proc_from_exec_nr IS NOT NULL)
        THEN
            g_error := 'if "process from day" value is not null, then the "process from execution number" value cannot be null also (and the contrary is applied likewise)';
            RAISE e_user_exception;
        ELSIF i_proc_from_day IS NOT NULL
              AND i_proc_from_day < i_order_plan_record.start_date
              AND i_flg_validate_proc_from = pk_alert_constant.g_yes
        THEN
            g_error := '"process from day" value is defined but it cannot be lower than the order start date';
            RAISE e_user_exception;
        ELSIF i_proc_from_day IS NOT NULL
              AND i_proc_from_day > io_plan_start_date
        THEN
            g_error := 'because "process from day" value is defined, the start plan timestamp cannot be lower than "process from day"';
            RAISE e_user_exception;
        END IF;*/
    
        -- if order plan end date is null, but it has a maximum duration
        IF i_order_plan_record.end_date IS NULL
           AND i_order_plan_record.flg_end_by = g_flg_end_by_duration
        THEN
            l_order_plan_end_date := add_offset_to_tstz(i_offset    => i_order_plan_record.duration,
                                                        i_timestamp => i_order_plan_record.start_date,
                                                        i_unit      => i_order_plan_record.id_unit_meas_duration);
            o_order_date_limit    := l_order_plan_end_date - 1; -- set order end date by defined duration
            -- limit the upper bound only if desired plan end interval is lower that the calculated "by duration" timestamp
            IF l_order_plan_end_date < io_plan_end_date
            THEN
                io_plan_end_date := l_order_plan_end_date;
            END IF;
            -- if order plan end date is lower than desired end interval, adjust plan end interval
        ELSIF i_order_plan_record.end_date < io_plan_end_date
        THEN
            io_plan_end_date := i_order_plan_record.end_date;
        END IF;
    
        -- adjust order start date
        IF i_proc_from_day IS NOT NULL
        THEN
            o_order_start_date := i_proc_from_day;
        ELSE
            o_order_start_date := i_order_plan_record.start_date;
        END IF;
    
        -- adjust plan execution number (if defined)
        IF i_proc_from_exec_nr IS NOT NULL
        THEN
            o_plan_exec_nr := i_proc_from_exec_nr;
        ELSE
            o_plan_exec_nr := 1;
        END IF;
    
        -- set order end date by defined end date
        IF i_order_plan_record.end_date IS NOT NULL
        THEN
            o_order_date_limit := i_order_plan_record.end_date;
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
                                              'SET_ORDER_PLAN_INTERVAL',
                                              o_error);
            RETURN FALSE;
    END set_order_plan_interval;

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
    
        UPDATE order_recurr_control
           SET last_exec_order = last_exec_order - 1
         WHERE id_order_recurr_plan = i_order_recurr_plan;
    
        RETURN TRUE;
    END;

    /********************************************************************************************
    * get execution number for the given start date
    *
    * @param       i_start_date           plan start date
    * @param       i_order_day            order day
    * @param       i_orcplt_exec          order plan execution timetable
    *
    * @return      boolean                execution number if >=1, otherwise zero
    *
    * @author                             Carlos Loureiro
    * @since                              18-APR-2011
    ********************************************************************************************/
    FUNCTION get_daily_exec_number
    (
        i_start_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_order_day   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_orcplt_exec IN t_tbl_orcplt
    ) RETURN PLS_INTEGER IS
        l_exec_ts TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- loop for all executions
        FOR i IN 1 .. i_orcplt_exec.count
        LOOP
            -- if defined, the positive or negative offset will be handled by add_offset_to_tstz function
            l_exec_ts := add_offset_to_tstz(i_orcplt_exec(i).exec_time_offset,
                                            i_order_day + i_orcplt_exec(i).exec_time,
                                            i_orcplt_exec(i).id_unit_meas_exec_time_offset);
            -- check if a suitable exec time was found
            IF l_exec_ts >= i_start_date
            THEN
                RETURN i;
            END IF;
        END LOOP;
        RETURN 0; -- no suitable exec time was found
    END get_daily_exec_number;

    /********************************************************************************************
    * get get next execution timestamp for the given order day and execution number
    *
    * @param       i_order_day                       order day
    * @param       i_orcplt_exec                     order plan execution timetable
    * @param       i_exec_number                     execution number
    *
    * @return      timestamp with local time zone    next execution timestamp
    *
    * @value       i_exec_number                     {*} !0 process next exec time within the same
    *                                                    order day
    *                                                {*} =0 process the 1st exec time in the day after
    *                                                    order day. It will update the i_exec_number
    *                                                    to 1 (1st exec time)
    *
    * @author                                        Carlos Loureiro
    * @since                                         19-APR-2011
    ********************************************************************************************/
    FUNCTION get_next_daily_exec_time
    (
        i_order_day    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_orcplt_exec  IN t_tbl_orcplt,
        io_exec_number IN OUT NOCOPY PLS_INTEGER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_plan_next_exec_ts TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- check if execution time will occur in the order day
        IF io_exec_number != 0
        THEN
            -- if so, then process that execution number
            l_plan_next_exec_ts := add_offset_to_tstz(i_offset    => i_orcplt_exec(io_exec_number).exec_time_offset,
                                                      i_timestamp => i_order_day + i_orcplt_exec(io_exec_number).exec_time,
                                                      i_unit      => i_orcplt_exec(io_exec_number).id_unit_meas_exec_time_offset);
        ELSE
            -- if not, then process the 1st execution number of the next day (order day + 1)
            l_plan_next_exec_ts := add_offset_to_tstz(i_offset    => i_orcplt_exec(1).exec_time_offset,
                                                      i_timestamp => i_order_day + 1 + i_orcplt_exec(1).exec_time,
                                                      i_unit      => i_orcplt_exec(1).id_unit_meas_exec_time_offset);
            io_exec_number      := 1; -- reset exec time plan for the 1st execution number
        END IF;
        RETURN l_plan_next_exec_ts;
    END get_next_daily_exec_time;

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
    
        l_or_flg_status        order_recurr_control.flg_status%TYPE;
        l_or_last_exec_order   order_recurr_control.last_exec_order%TYPE;
        l_or_dt_last_exec      order_recurr_control.dt_last_exec%TYPE;
        r_order_recurr_plan    order_recurr_plan%ROWTYPE;
        r_order_recurr_control order_recurr_control%ROWTYPE;
        l_plan_finish          VARCHAR2(2 CHAR);
    
        l_id_market market.id_market%TYPE;
        l_interval  order_recurr_control_cfg.interval_value%TYPE;
    
        l_dt_start TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_order_plan_tab t_tbl_order_recurr_plan;
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_plan_calc_mode sys_config.value%TYPE;
    
    BEGIN
    
        IF NOT pk_order_recurrence_core.get_order_recurr_plan_status(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_order_recurr_plan => i_id_order_recurrence,
                                                                     o_flg_status        => l_or_flg_status,
                                                                     o_last_exec_order   => l_or_last_exec_order,
                                                                     o_dt_last_exec      => l_or_dt_last_exec,
                                                                     o_error             => o_error)
        THEN
            RAISE e_user_exception;
        END IF;
    
        o_flag_recurr_control := l_or_flg_status;
    
        IF (l_or_flg_status = pk_order_recurrence_core.g_flg_status_control_active AND i_is_edit < 1)
        THEN
        
            g_error := 'CALL pk_order_recurrence_core.update_execution_plan';
        
            SELECT *
              INTO r_order_recurr_plan
              FROM order_recurr_plan
             WHERE id_order_recurr_plan = i_id_order_recurrence;
        
            SELECT *
              INTO r_order_recurr_control
              FROM order_recurr_control
             WHERE id_order_recurr_plan = i_id_order_recurrence;
        
            l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
        
            IF NOT pk_order_recurrence_core.get_order_recurr_cfg(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_order_recurr_area => r_order_recurr_plan.id_order_recurr_area,
                                                                 i_interval_name     => pk_order_recurrence_core.g_cfg_name_active_window,
                                                                 i_id_market         => l_id_market,
                                                                 o_interval_value    => l_interval,
                                                                 o_error             => o_error)
            THEN
                RAISE e_user_exception;
            END IF;
        
            l_dt_start := r_order_recurr_control.dt_last_processed;
            l_dt_end   := l_sysdate + l_interval;
        
            l_plan_calc_mode := pk_sysconfig.get_config('INTERV_START_DATE', i_prof);
        
            IF l_plan_calc_mode = pk_procedures_constant.g_interv_system_date
            --AND r_order_recurr_plan.regular_interval IS NOT NULL
            THEN
                IF i_flg_next_change = pk_alert_constant.g_yes
                   OR i_dt_next IS NOT NULL
                THEN
                    l_dt_start := nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_next, NULL), l_sysdate);
                ELSE
                    IF r_order_recurr_control.last_exec_order <= 1
                    THEN
                        l_dt_start := l_sysdate;
                    END IF;
                END IF;
            ELSE
                IF i_flg_next_change = pk_alert_constant.g_yes
                THEN
                    l_dt_start := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_next, NULL);
                END IF;
            END IF;
        
            IF r_order_recurr_plan.regular_interval IS NOT NULL
            THEN
            
                l_dt_end := pk_order_recurrence_core.add_offset_to_tstz(i_offset    => r_order_recurr_plan.regular_interval,
                                                                        i_timestamp => l_dt_start,
                                                                        i_unit      => r_order_recurr_plan.id_unit_meas_regular_interval);
            ELSE
            
                IF r_order_recurr_plan.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_none
                THEN
                    l_dt_end := l_dt_start + numtodsinterval(1, 'DAY');
                ELSIF r_order_recurr_plan.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_daily
                THEN
                    l_dt_end := l_dt_start + numtodsinterval(r_order_recurr_plan.repeat_every, 'DAY');
                ELSIF r_order_recurr_plan.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_weekly
                THEN
                    l_dt_end := l_dt_start + numtodsinterval(7 * r_order_recurr_plan.repeat_every, 'DAY');
                ELSIF r_order_recurr_plan.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_monthly
                THEN
                    l_dt_end := l_dt_start + numtoyminterval(r_order_recurr_plan.repeat_every, 'MONTH');
                ELSIF r_order_recurr_plan.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_yearly
                THEN
                    l_dt_end := l_dt_start + numtoyminterval(r_order_recurr_plan.repeat_every, 'YEAR');
                ELSE
                    l_dt_end := l_dt_start + 1;
                END IF;
            
            END IF;
        
            IF l_dt_start > l_dt_end
            THEN
                l_dt_start := l_dt_end;
            END IF;
            g_error := 'Check l_dt_start and l_dt_end';
        
            IF NOT pk_order_recurrence_core.get_order_recurr_plan(i_lang              => i_lang,
                                                                  i_prof              => i_prof,
                                                                  i_order_plan        => r_order_recurr_control.id_order_recurr_plan,
                                                                  i_plan_start_date   => l_dt_start,
                                                                  i_plan_end_date     => l_dt_end,
                                                                  i_proc_from_day     => l_dt_start,
                                                                  i_proc_from_exec_nr => r_order_recurr_control.last_exec_order,
                                                                  o_order_plan        => l_order_plan_tab,
                                                                  o_last_exec_reached => l_plan_finish,
                                                                  o_error             => o_error)
            THEN
                RAISE e_user_exception;
            END IF;
        
            IF l_order_plan_tab.count <= 1
               OR (r_order_recurr_control.last_exec_order =
               r_order_recurr_plan.occurrences * r_order_recurr_plan.daily_executions AND
               r_order_recurr_plan.regular_interval IS NULL)
               OR (r_order_recurr_control.last_exec_order = r_order_recurr_plan.occurrences AND
               r_order_recurr_plan.regular_interval IS NOT NULL)
               OR (r_order_recurr_control.last_exec_order = r_order_recurr_plan.occurrences AND
               r_order_recurr_plan.flg_recurr_pattern <> pk_order_recurrence_core.g_flg_recurr_pattern_none)
               OR (r_order_recurr_plan.flg_end_by = pk_order_recurrence_core.g_flg_end_by_date AND
               l_dt_end >= r_order_recurr_plan.end_date)
            THEN
                o_finish_recurr   := pk_alert_constant.get_yes;
                o_plan_start_date := NULL;
                RETURN TRUE;
            
            END IF;
        
            -- Insert new Execution Procedure and Update EA
            FOR i IN 1 .. l_order_plan_tab.count
            LOOP
                CASE l_plan_calc_mode
                    WHEN pk_procedures_constant.g_interv_system_date THEN
                        IF l_order_plan_tab(i)
                         .exec_timestamp > r_order_recurr_control.dt_last_processed
                            AND l_order_plan_tab(i).exec_timestamp > l_sysdate
                            OR (l_order_plan_tab(i).exec_timestamp = r_order_recurr_control.dt_last_processed AND
                                 r_order_recurr_control.last_exec_order = 1)
                            OR (l_order_plan_tab(i).exec_timestamp <= r_order_recurr_control.dt_last_processed AND
                                 i_flg_next_change = pk_alert_constant.g_yes)
                        THEN
                            o_plan_start_date := l_order_plan_tab(i).exec_timestamp;
                            EXIT;
                        END IF;
                    ELSE
                        IF l_order_plan_tab(i)
                         .exec_timestamp > r_order_recurr_control.dt_last_processed
                            OR (l_order_plan_tab(i).exec_timestamp = r_order_recurr_control.dt_last_processed AND
                                 r_order_recurr_control.last_exec_order = 1)
                            OR (l_order_plan_tab(i).exec_timestamp <= r_order_recurr_control.dt_last_processed AND
                                 i_flg_next_change = pk_alert_constant.g_yes)
                        THEN
                            o_plan_start_date := l_order_plan_tab(i).exec_timestamp;
                            EXIT;
                        END IF;
                END CASE;
            END LOOP;
        
            IF o_plan_start_date IS NULL
            THEN
                FOR i IN 1 .. l_order_plan_tab.count
                LOOP
                    CASE l_plan_calc_mode
                        WHEN pk_procedures_constant.g_interv_system_date THEN
                            IF l_order_plan_tab(i)
                             .exec_timestamp > l_sysdate
                                OR (l_order_plan_tab(i).exec_timestamp = r_order_recurr_control.dt_last_processed AND
                                     r_order_recurr_control.last_exec_order = 1)
                                OR (l_order_plan_tab(i).exec_timestamp <= r_order_recurr_control.dt_last_processed AND
                                     i_flg_next_change = pk_alert_constant.g_yes)
                            THEN
                                o_plan_start_date := l_order_plan_tab(i).exec_timestamp;
                                EXIT;
                            END IF;
                        ELSE
                            IF (l_order_plan_tab(i).exec_timestamp = r_order_recurr_control.dt_last_processed AND
                                r_order_recurr_control.last_exec_order = 1)
                               OR (l_order_plan_tab(i).exec_timestamp <= r_order_recurr_control.dt_last_processed AND
                                i_flg_next_change = pk_alert_constant.g_yes)
                            THEN
                                o_plan_start_date := l_order_plan_tab(i).exec_timestamp;
                                EXIT;
                            END IF;
                    END CASE;
                END LOOP;
            END IF;
        
            IF r_order_recurr_plan.id_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
            THEN
                o_plan_start_date := l_sysdate;
            END IF;
        
            IF i_to_execute = pk_alert_constant.get_yes
            THEN
                g_error := 'CALL PK_ORDER_RECURRENCE_CORE.UPDATE_RECURR_CONTROL_PROC';
                IF NOT pk_order_recurrence_core.update_recurr_control_proc(i_lang                 => i_lang,
                                                                           i_prof                 => i_prof,
                                                                           i_id_order_recurr_plan => r_order_recurr_plan.id_order_recurr_plan,
                                                                           i_date_plan            => o_plan_start_date,
                                                                           o_error                => o_error)
                THEN
                    RAISE e_user_exception;
                END IF;
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
                                              'GET_RECURR_OPTION_TIME',
                                              o_error);
            RETURN FALSE;
        
    END get_next_execution;

    /********************************************************************************************
    * get execution times of an order recurrence option list
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_recurr_option  list of order recurrence option ids
    * @param       o_order_recurr_time    array of order recurrence times
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Tiago Silva
    * @since                              20-APR-2011
    ********************************************************************************************/
    FUNCTION get_recurr_option_time
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_order_recurr_option IN table_number,
        o_order_recurr_time   OUT t_tbl_orcotmsi,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        -- get institution market
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        -- get professional profile template
        l_id_prof_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    BEGIN
    
        g_error := 'get o_order_recurr_time array data';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT t_rec_orcotmsi(id_order_recurr_option, exec_time, exec_time_offset, id_unit_meas_exec_time_offset)
          BULK COLLECT
          INTO o_order_recurr_time
          FROM (SELECT DISTINCT /*+opt_estimate(table orco rows=1)*/ first_value(orcotmsi.id_order_recurr_option) over(PARTITION BY orcotmsi.id_order_recurr_option ORDER BY orcotmsi.id_institution DESC, orcotmsi.id_market DESC, orcotmsi.id_software DESC, orcotmsi.id_profile_template DESC) AS id_order_recurr_option,
                                first_value(orcotmsi.exec_time) over(PARTITION BY orcotmsi.id_order_recurr_option ORDER BY orcotmsi.id_institution DESC, orcotmsi.id_market DESC, orcotmsi.id_software DESC, orcotmsi.id_profile_template DESC) AS exec_time,
                                first_value(orcotmsi.exec_time_offset) over(PARTITION BY orcotmsi.id_order_recurr_option ORDER BY orcotmsi.id_institution DESC, orcotmsi.id_market DESC, orcotmsi.id_software DESC, orcotmsi.id_profile_template DESC) AS exec_time_offset,
                                first_value(orcotmsi.id_unit_meas_exec_time_offset) over(PARTITION BY orcotmsi.id_order_recurr_option ORDER BY orcotmsi.id_institution DESC, orcotmsi.id_market DESC, orcotmsi.id_software DESC, orcotmsi.id_profile_template DESC) AS id_unit_meas_exec_time_offset,
                                first_value(orcotmsi.flg_available) over(PARTITION BY orcotmsi.id_order_recurr_option ORDER BY orcotmsi.id_institution DESC, orcotmsi.id_market DESC, orcotmsi.id_software DESC, orcotmsi.id_profile_template DESC) AS flg_available
                  FROM order_recurr_option_time_msi orcotmsi
                 INNER JOIN TABLE(i_order_recurr_option) orco
                    ON (orcotmsi.id_order_recurr_option = orco.column_value)
                 WHERE orcotmsi.id_market IN (l_id_market, pk_alert_constant.g_id_market_all)
                   AND orcotmsi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND orcotmsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                   AND orcotmsi.id_profile_template IN
                       (l_id_prof_profile_template, pk_alert_constant.g_profile_template_all))
         WHERE flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RECURR_OPTION_TIME',
                                              o_error);
            RETURN FALSE;
    END get_recurr_option_time;

    /********************************************************************************************
    * process recurrence pattern executions
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_order_plan           order recurrence plan id
    * @param       i_daily_exec_nr        the number of daily executions
    * @param       i_default_interval     default interval value to consider when there are no defined exec times
    * @param       o_orcplt_exec          structure with processed execution times plan
    * @param       o_flg_has_exact_times  flag that indicates if the plan has exact times or not
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              20-APR-2011
    ********************************************************************************************/
    FUNCTION get_daily_exec_time_plan
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_order_plan            IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_daily_exec_nr         IN order_recurr_plan.daily_executions%TYPE,
        i_default_exec_interval IN INTERVAL DAY TO SECOND,
        o_orcplt_exec           OUT t_tbl_orcplt,
        o_flg_has_exact_times   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_recurr_option table_number;
        l_orcplt_exec_aux     t_tbl_orcplt;
        l_order_time_option   t_tbl_orcotmsi;
    BEGIN
        -- get exec times from the plan
        g_error := 'get execution times from order recurrence plan [' || i_order_plan || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT t_rec_orcplt(orcplt.id_order_recurr_plan_time,
                            orcplt.id_order_recurr_plan,
                            orcplt.id_order_recurr_option_parent,
                            orcplt.id_order_recurr_option_child,
                            orcplt.exec_time,
                            orcplt.exec_time_offset,
                            orcplt.id_unit_meas_exec_time_offset)
          BULK COLLECT
          INTO l_orcplt_exec_aux
          FROM order_recurr_plan_time orcplt
         WHERE orcplt.id_order_recurr_plan = i_order_plan
         ORDER BY orcplt.exec_time;
        -- process predefined options in current exec time plan (where available)
        SELECT DISTINCT id_order_recurr_option
          BULK COLLECT
          INTO l_order_recurr_option
          FROM (SELECT orcplt_child.id_order_recurr_option_child AS id_order_recurr_option
                  FROM TABLE(CAST(l_orcplt_exec_aux AS t_tbl_orcplt)) orcplt_child
                 WHERE orcplt_child.id_order_recurr_option_child IS NOT NULL
                UNION ALL
                SELECT orcplt_parent.id_order_recurr_option_parent AS id_order_recurr_option
                  FROM TABLE(CAST(l_orcplt_exec_aux AS t_tbl_orcplt)) orcplt_parent
                 WHERE orcplt_parent.id_order_recurr_option_parent IS NOT NULL);
        -- if there are order recurrence options defined, then use the option's content instead of transactional data, if available
        IF l_order_recurr_option.count != 0
        THEN
            -- get available content options for given recurrence options
            IF NOT get_recurr_option_time(i_lang                => i_lang,
                                          i_prof                => i_prof,
                                          i_order_recurr_option => l_order_recurr_option,
                                          o_order_recurr_time   => l_order_time_option,
                                          o_error               => o_error)
            THEN
                g_error := 'error while calling get_recurr_option_time function';
                RAISE e_user_exception;
            END IF;
            -- get exec times from the option's content instead of transaccional data, if available
            SELECT t_rec_orcplt(id_order_recurr_plan_time,
                                id_order_recurr_plan,
                                id_order_recurr_option_parent,
                                id_order_recurr_option_child,
                                exec_time,
                                exec_time_offset,
                                id_unit_meas_exec_time_offset)
              BULK COLLECT
              INTO o_orcplt_exec
              FROM (SELECT orcplt.id_order_recurr_plan_time AS id_order_recurr_plan_time,
                           orcplt.id_order_recurr_plan AS id_order_recurr_plan,
                           orcotmsi_parent.id_order_recurr_option AS id_order_recurr_option_parent,
                           orcotmsi_child.id_order_recurr_option AS id_order_recurr_option_child,
                           nvl2(orcotmsi_child.id_order_recurr_option, orcotmsi_child.exec_time, orcplt.exec_time) AS exec_time,
                           nvl2(orcotmsi_child.id_order_recurr_option,
                                orcotmsi_child.exec_time_offset,
                                orcplt.exec_time_offset) AS exec_time_offset,
                           nvl2(orcotmsi_child.id_order_recurr_option,
                                orcotmsi_child.id_unit_meas_exec_time_offset,
                                orcotmsi_child.id_unit_meas_exec_time_offset) AS id_unit_meas_exec_time_offset
                      FROM TABLE(CAST(l_orcplt_exec_aux AS t_tbl_orcplt)) orcplt
                      LEFT JOIN TABLE(CAST(l_order_time_option AS t_tbl_orcotmsi)) orcotmsi_child
                        ON orcplt.id_order_recurr_option_child = orcotmsi_child.id_order_recurr_option
                      LEFT JOIN TABLE(CAST(l_order_time_option AS t_tbl_orcotmsi)) orcotmsi_parent
                        ON orcplt.id_order_recurr_option_parent = orcotmsi_parent.id_order_recurr_option)
             ORDER BY exec_time;
        
            IF o_orcplt_exec.count > 0
            THEN
                o_flg_has_exact_times := pk_alert_constant.g_yes;
            ELSE
                o_flg_has_exact_times := pk_alert_constant.g_no;
            END IF;
        
        ELSE
            -- consider only the transactional data plan, if exec times are available
            IF l_orcplt_exec_aux.count > 0
            THEN
                o_orcplt_exec := l_orcplt_exec_aux;
            
                o_flg_has_exact_times := pk_alert_constant.g_yes;
            ELSE
                -- create the exec times collection with the default interval
                o_orcplt_exec := t_tbl_orcplt();
                FOR i IN 1 .. i_daily_exec_nr
                LOOP
                    o_orcplt_exec.extend;
                    o_orcplt_exec(i) := t_rec_orcplt(NULL,
                                                     i_order_plan,
                                                     NULL,
                                                     NULL,
                                                     i_default_exec_interval,
                                                     NULL,
                                                     NULL);
                END LOOP;
            
                o_flg_has_exact_times := pk_alert_constant.g_no;
            
            END IF;
        END IF;
        -- now, the o_orcplt_exec have the daily execution times
        -- when looking to this array, the records are always sorted from the beggining to the end of each day
        -- position (1): first execution of the day, position (2): second execution of the day, and so on...
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DAILY_EXEC_TIME_PLAN',
                                              o_error);
            RETURN FALSE;
    END get_daily_exec_time_plan;

    /********************************************************************************************
    * process recurrence pattern executions
    *
    * @param       i_lang                 preferred language id
    * @param       i_prof                 professional structure
    * @param       i_rec_orcpl            order recurrence plan information
    * @param       io_repeat_every        repeat every process control variable
    * @param       io_repeat_every_anchor repeat every anchor process control variable
    * @param       io_order_day           order day process control variable
    * @param       i_order_start_day      order plan start day timestamp
    * @param       i_plan_next_exec_ts    order plan next execution timestamp
    * @param       io_plan                processed order recurrence plan
    * @param       io_plan_exec           processed order recurrence plan execution number
    * @param       io_plan_idx            processed order recurrence plan collection index number
    * @param       i_order_plan_end_date  end timestamp for the order recurrence plan
    * @param       o_flg_last_exec        last execution flag process control variable
    * @param       o_flg_plan_end         last execution of order plan was reached (no more executions
    *                                     will be processed in this plan)
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Carlos Loureiro
    * @since                              20-APR-2011
    ********************************************************************************************/
    FUNCTION process_recurr_pattern_exec
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_rec_orcpl            IN order_recurr_plan%ROWTYPE,
        io_repeat_every        IN OUT NOCOPY PLS_INTEGER,
        io_repeat_every_anchor IN OUT NOCOPY PLS_INTEGER,
        io_order_day           IN OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        i_order_start_day      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_plan_next_exec_ts    IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_plan                IN OUT NOCOPY t_tbl_order_recurr_plan,
        io_plan_exec           IN OUT NOCOPY PLS_INTEGER,
        io_plan_idx            IN OUT NOCOPY PLS_INTEGER,
        i_order_plan_end_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_last_exec        OUT BOOLEAN,
        i_order_date_limit     IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_plan_end         OUT BOOLEAN,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_process_next_exec BOOLEAN;
    BEGIN
        g_error := 'processing recurrence pattern';
        pk_alertlog.log_debug(g_error, g_package_name);
        -- if we have a recurrence pattern, then the repeat every interval is set
        IF i_rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none
        THEN
            g_error := 'processing recurrence pattern 1' || io_order_day;
            pk_alertlog.log_debug(g_error, g_package_name);
        
            io_repeat_every := get_timestamp_diff(i_flg_recurr_pattern => i_rec_orcpl.flg_recurr_pattern,
                                                  i_timestamp_from     => CASE i_rec_orcpl.flg_recurr_pattern
                                                                              WHEN g_flg_recurr_pattern_monthly THEN
                                                                               i_order_start_day
                                                                              ELSE
                                                                               io_order_day
                                                                          END,
                                                  i_timestamp_to       => i_plan_next_exec_ts);
        
            -- check if repeat every interval was reached and if we're not considering 2 timestamps for the same day
            IF (NOT check_timestamps_same_day(io_order_day, i_plan_next_exec_ts) AND
               io_repeat_every - io_repeat_every_anchor < i_rec_orcpl.repeat_every)
               OR i_rec_orcpl.occurrences <= 1 -- do not include the next ts into the collection if we have 1 occurrences restrition
            THEN
                l_process_next_exec := FALSE; -- don't process the next execution
            ELSE
                -- update interval lower bound to process next iterations
                io_order_day := get_timestamp_day_tstz(i_lang, i_prof, i_plan_next_exec_ts);
                -- when in monthly recurrence pattern, the month day needs to be calculated from the l_order_start_day
                IF i_rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_monthly
                THEN
                    -- update anchor point to enable differences from l_order_start_day
                    io_repeat_every_anchor := get_timestamp_diff(i_flg_recurr_pattern => i_rec_orcpl.flg_recurr_pattern,
                                                                 i_timestamp_from     => i_order_start_day,
                                                                 i_timestamp_to       => i_plan_next_exec_ts);
                END IF;
                l_process_next_exec := TRUE; -- process the next execution
            END IF;
        ELSE
            g_error := 'processing recurrence pattern 2';
            pk_alertlog.log_debug(g_error, g_package_name);
            -- rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none
            -- allow other executions if they are in the same day
            IF check_timestamps_same_day(io_order_day, i_plan_next_exec_ts)
            THEN
                l_process_next_exec := TRUE;
            ELSE
                l_process_next_exec := FALSE;
            END IF;
        END IF;
    
        -- if next execution should be processed
        IF l_process_next_exec
        THEN
            -- process the next execution
            io_plan_exec := io_plan_exec + 1;
            io_plan_idx  := io_plan_idx + 1;
            -- process only the collection if io_plan is not null (used when we don't need the collection filled with data)
            IF io_plan IS NOT NULL
            THEN
                io_plan.extend;
                io_plan(io_plan_idx) := t_rec_order_recurr_plan(i_rec_orcpl.id_order_recurr_plan,
                                                                io_plan_exec,
                                                                i_plan_next_exec_ts);
            END IF;
            g_error := 'execution number [' || io_plan_exec || '] processed successfully with [' || i_plan_next_exec_ts ||
                       '] timestamp';
            pk_alertlog.log_debug(g_error, g_package_name);
        ELSE
            g_error := 'execution number [' || io_plan_exec || '] with [' || i_plan_next_exec_ts ||
                       '] timestamp will be skipped';
            pk_alertlog.log_debug(g_error, g_package_name);
        END IF;
    
        -- evaluate if loop stop condition was reached
        -- if next execution is greater than plan end date or order request end date
        IF (i_rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none AND
           i_rec_orcpl.flg_end_by IN (g_flg_end_by_date, g_flg_end_by_duration) AND
           ((i_plan_next_exec_ts >= i_order_plan_end_date AND i_rec_orcpl.daily_executions = 1) OR
           (i_plan_next_exec_ts > i_order_plan_end_date /*AND i_rec_orcpl.daily_executions != 1*/
           )))
           OR (i_rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none AND
           i_rec_orcpl.flg_end_by = g_flg_end_by_no_end AND
           (i_order_plan_end_date IS NULL OR i_plan_next_exec_ts > i_order_plan_end_date))
        
        THEN
            o_flg_last_exec := TRUE; -- last execution for the desired plan interval was reached
            -- check if last execution of entire order plan was reached, if we have a defined limit
            IF i_order_date_limit IS NOT NULL
               AND i_order_date_limit <= i_plan_next_exec_ts
            THEN
                o_flg_plan_end := TRUE; -- last execution for the entire plan was reached
            ELSE
                o_flg_plan_end := FALSE; -- last execution for the entire plan wasn't reached
            END IF;
        
            -- or if we have a recurrence pattern and the number of requested executions was reached
        ELSIF (i_rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none AND
              (i_rec_orcpl.flg_end_by = g_flg_end_by_occurrences AND io_plan_exec >= i_rec_orcpl.occurrences))
        THEN
            o_flg_last_exec := TRUE; -- last execution for the desired plan interval was reached
            IF i_order_plan_end_date IS NULL
            THEN
                o_flg_plan_end := TRUE; -- assume that the last execution for the entire plan was reached if the end interval is not set
            ELSIF i_plan_next_exec_ts < i_order_plan_end_date
            THEN
                o_flg_plan_end := TRUE; -- last execution for the entire plan was reached also
            ELSE
                o_flg_plan_end := FALSE; -- last execution for the entire plan wasn't reached
            END IF;
        
            -- or if we don't have a recurrence pattern and the last execution was reached
        ELSIF (i_rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none AND NOT l_process_next_exec)
        THEN
            o_flg_last_exec := TRUE; -- last execution for the desired plan interval was reached
            o_flg_plan_end  := TRUE; -- last execution for the entire plan was reached also
        
            -- last execution wasn't reached
        ELSE
            o_flg_last_exec := FALSE; -- last execution for the desired interval plan wasn't processed yet
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
                                              'PROCESS_RECURR_PATTERN_EXEC',
                                              o_error);
            RETURN FALSE;
    END process_recurr_pattern_exec;

    FUNCTION update_recurr_control_proc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_date_plan            IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        UPDATE order_recurr_control
           SET dt_last_exec = dt_last_processed, last_exec_order = last_exec_order + 1, dt_last_processed = i_date_plan
         WHERE id_order_recurr_plan = i_id_order_recurr_plan;
    
        RETURN TRUE;
    END update_recurr_control_proc;

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
    
        UPDATE order_recurr_control
           SET dt_last_processed = i_dt_last_processed
         WHERE id_order_recurr_plan = i_order_recurr_plan;
    
        RETURN TRUE;
    END update_order_control_last_exec;

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
    ) RETURN BOOLEAN IS
        rec_orcpl               order_recurr_plan%ROWTYPE;
        l_order_start_date      order_recurr_plan.start_date%TYPE;
        l_plan                  t_tbl_order_recurr_plan := t_tbl_order_recurr_plan();
        l_plan_exec             PLS_INTEGER;
        l_plan_idx              PLS_INTEGER := 1;
        l_plan_next_exec_ts     TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_plan_start_date TIMESTAMP WITH LOCAL TIME ZONE := i_plan_start_date;
        l_order_plan_end_date   TIMESTAMP WITH LOCAL TIME ZONE := i_plan_end_date;
        l_order_day             TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_start_day       TIMESTAMP WITH LOCAL TIME ZONE;
        l_repeat_every          PLS_INTEGER;
        l_repeat_every_anchor   PLS_INTEGER;
        l_flg_last_exec         BOOLEAN;
        l_orcplt_exec           t_tbl_orcplt;
        l_orcplt_exec_nr        PLS_INTEGER;
        l_order_date_limit      TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_plan_end          BOOLEAN;
        l_watchdog_counter      PLS_INTEGER := 1;
    
        l_flg_has_exact_times VARCHAR2(1 CHAR);
    
    BEGIN
        -- get record from order_recurr_plan table
        g_error := 'get record from order_recurr_plan table, where id_order_recurr_plan is [' || i_order_plan || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT *
          INTO rec_orcpl
          FROM order_recurr_plan orcpl
         WHERE orcpl.id_order_recurr_plan = i_order_plan
           AND orcpl.flg_status = g_plan_status_final;
    
        -- validate and adjust plan interval according to the order recurrence plan
        IF NOT set_order_plan_interval(i_lang                   => i_lang,
                                       io_plan_start_date       => l_order_plan_start_date,
                                       io_plan_end_date         => l_order_plan_end_date,
                                       i_proc_from_day          => i_proc_from_day,
                                       i_proc_from_exec_nr      => i_proc_from_exec_nr,
                                       i_flg_validate_proc_from => i_flg_validate_proc_from,
                                       i_order_plan_record      => rec_orcpl,
                                       o_plan_exec_nr           => l_plan_exec,
                                       o_order_start_date       => l_order_start_date,
                                       o_order_date_limit       => l_order_date_limit,
                                       o_error                  => o_error)
        THEN
            g_error := 'error found while calling set_order_plan_interval function';
            RAISE e_user_exception;
        END IF;
    
        -- check if regular interval field is set
        IF rec_orcpl.regular_interval IS NOT NULL
        THEN
            -- #######################
            -- ## REGULAR INTERVALS ##
            -- #######################
        
            -- process the first execution
            g_error := 'process the first execution';
            pk_alertlog.log_debug(g_error, g_package_name);
            l_plan.extend;
            l_plan(l_plan_idx) := t_rec_order_recurr_plan(rec_orcpl.id_order_recurr_plan,
                                                          l_plan_exec,
                                                          l_order_start_date);
            g_error := 'execution number [' || l_plan_exec || '] processed successfully with [' || l_order_start_date ||
                       '] timestamp';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- anchor point (start the recurrence variables)
            l_plan_next_exec_ts   := l_order_start_date;
            l_order_day           := get_timestamp_day_tstz(i_lang, i_prof, l_order_start_date);
            l_order_start_day     := l_order_day;
            l_repeat_every_anchor := 0;
            LOOP
                -- calculate the next execution
                g_error := 'process the next execution';
                pk_alertlog.log_debug(g_error, g_package_name);
                l_plan_next_exec_ts := add_offset_to_tstz(i_offset    => rec_orcpl.regular_interval,
                                                          i_timestamp => l_plan_next_exec_ts,
                                                          i_unit      => rec_orcpl.id_unit_meas_regular_interval);
                -- process this execution using plan recurrence pattern and indicates if this is the last execution for the given plan interval
                IF NOT process_recurr_pattern_exec(i_lang                 => i_lang,
                                                   i_prof                 => i_prof,
                                                   i_rec_orcpl            => rec_orcpl,
                                                   io_repeat_every        => l_repeat_every,
                                                   io_repeat_every_anchor => l_repeat_every_anchor,
                                                   io_order_day           => l_order_day,
                                                   i_order_start_day      => l_order_start_day,
                                                   i_plan_next_exec_ts    => l_plan_next_exec_ts,
                                                   io_plan                => l_plan,
                                                   io_plan_exec           => l_plan_exec,
                                                   io_plan_idx            => l_plan_idx,
                                                   i_order_plan_end_date  => l_order_plan_end_date,
                                                   o_flg_last_exec        => l_flg_last_exec,
                                                   i_order_date_limit     => l_order_date_limit,
                                                   o_flg_plan_end         => l_flg_plan_end,
                                                   o_error                => o_error)
                THEN
                    g_error := 'error found while calling process_recurr_pattern_exec function for regular intervals frequency';
                    RAISE e_user_exception;
                END IF;
                -- evaluate if last execution was processed
                IF l_flg_last_exec
                THEN
                    EXIT; -- exit loop
                END IF;
                -- watchdog counter
                l_watchdog_counter := l_watchdog_counter + 1;
                IF l_watchdog_counter > g_watchdog_count_limit
                THEN
                    g_error := 'watchdog loop counter limit value reached [' || g_watchdog_count_limit || ']';
                    RAISE e_user_exception;
                END IF;
            END LOOP;
        
            -- check if daily executions field is set
        ELSIF rec_orcpl.daily_executions IS NOT NULL
              AND rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none
        THEN
            -- ######################
            -- ## DAILY EXECUTIONS ##
            -- ######################
        
            -- check if start date must be included as the first execution
            IF (rec_orcpl.flg_include_start_date_in_plan = pk_alert_constant.g_yes)
            THEN
                -- process the first execution
                g_error := 'process the first execution';
                pk_alertlog.log_debug(g_error, g_package_name);
                l_plan.extend;
                l_plan(l_plan_idx) := t_rec_order_recurr_plan(rec_orcpl.id_order_recurr_plan,
                                                              l_plan_exec,
                                                              l_order_start_date);
                g_error := 'execution number [' || l_plan_exec || '] processed successfully with [' ||
                           l_order_start_date || '] timestamp';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- prepare variables to process next execution
                l_plan_idx  := l_plan_idx + 1;
                l_plan_exec := l_plan_exec + 1;
            END IF;
        
            -- init order day
            l_order_day := get_timestamp_day_tstz(i_lang, i_prof, l_order_start_date);
            -- get exec times from order_recurr_plan_time table
            g_error := 'process records from order_recurr_plan_time table, where id_order_recurr_plan is [' ||
                       i_order_plan || ']';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF NOT get_daily_exec_time_plan(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_order_plan            => i_order_plan,
                                            i_daily_exec_nr         => rec_orcpl.daily_executions,
                                            i_default_exec_interval => l_order_start_date - l_order_day,
                                            o_orcplt_exec           => l_orcplt_exec,
                                            o_flg_has_exact_times   => l_flg_has_exact_times,
                                            o_error                 => o_error)
            THEN
                g_error := 'error found while calling get_daily_exec_time_plan function';
                RAISE e_user_exception;
            END IF;
            -- now l_orcplt_exec collection has the daily execution times.
            -- when looking to this array, the records are always sorted from the beggining to the end of each day
            -- position (1): first execution of the day, position (2): second execution of the day, and so on...
        
            -- find daily execution number for the start day
            l_orcplt_exec_nr := get_daily_exec_number(i_start_date  => l_order_start_date,
                                                      i_order_day   => l_order_day,
                                                      i_orcplt_exec => l_orcplt_exec);
            -- if no exec time was found, then use the 1st exec time of the next day
            IF l_orcplt_exec_nr = 0
            THEN
                l_order_day      := l_order_day + 1; -- because the next exec time will occur only in the next day
                l_orcplt_exec_nr := 1; -- reset exec time plan for the 1st exec time number
            END IF;
            l_order_start_day     := l_order_day;
            l_repeat_every_anchor := 0;
        
            -- get start execution timestamp
            l_plan_next_exec_ts := add_offset_to_tstz(i_offset    => l_orcplt_exec(l_orcplt_exec_nr).exec_time_offset,
                                                      i_timestamp => l_order_day + l_orcplt_exec(l_orcplt_exec_nr).exec_time,
                                                      i_unit      => l_orcplt_exec(l_orcplt_exec_nr).id_unit_meas_exec_time_offset);
            -- process the first execution
            g_error := 'process the first execution';
            pk_alertlog.log_debug(g_error, g_package_name);
            l_plan.extend;
            l_plan(l_plan_idx) := t_rec_order_recurr_plan(rec_orcpl.id_order_recurr_plan,
                                                          l_plan_exec,
                                                          l_plan_next_exec_ts);
            g_error := 'execution number [' || l_plan_exec || '] processed successfully with [' || l_plan_next_exec_ts ||
                       '] timestamp';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            LOOP
                -- process next daily execution number
                l_orcplt_exec_nr := l_orcplt_exec_nr + 1;
                IF l_orcplt_exec_nr > rec_orcpl.daily_executions
                THEN
                    -- jump to the 1st exec time of the next day by assigning l_orcplt_exec_nr to zero
                    l_orcplt_exec_nr := 0; -- 1st exec time of the next day (get_next_daily_exec_time can handle this value)
                END IF;
                -- calculate the next execution
                g_error := 'process the next execution';
                pk_alertlog.log_debug(g_error, g_package_name);
                l_plan_next_exec_ts := get_next_daily_exec_time(i_order_day    => get_timestamp_day_tstz(i_lang,
                                                                                                         i_prof,
                                                                                                         l_plan_next_exec_ts),
                                                                i_orcplt_exec  => l_orcplt_exec,
                                                                io_exec_number => l_orcplt_exec_nr); -- execution number will be updated also, if needed
                -- process this execution using plan recurrence pattern and indicates if this is the last execution for the given plan interval
                IF NOT process_recurr_pattern_exec(i_lang                 => i_lang,
                                                   i_prof                 => i_prof,
                                                   i_rec_orcpl            => rec_orcpl,
                                                   io_repeat_every        => l_repeat_every,
                                                   io_repeat_every_anchor => l_repeat_every_anchor,
                                                   io_order_day           => l_order_day,
                                                   i_order_start_day      => l_order_start_day,
                                                   i_plan_next_exec_ts    => l_plan_next_exec_ts,
                                                   io_plan                => l_plan,
                                                   io_plan_exec           => l_plan_exec,
                                                   io_plan_idx            => l_plan_idx,
                                                   i_order_plan_end_date  => l_order_plan_end_date,
                                                   o_flg_last_exec        => l_flg_last_exec,
                                                   i_order_date_limit     => l_order_date_limit,
                                                   o_flg_plan_end         => l_flg_plan_end,
                                                   o_error                => o_error)
                THEN
                    g_error := 'error found while calling process_recurr_pattern_exec function for daily executions frequency';
                    RAISE e_user_exception;
                END IF;
                -- evaluate if last execution was processed
                IF l_flg_last_exec
                THEN
                    EXIT; -- exit loop
                END IF;
                -- watchdog counter
                l_watchdog_counter := l_watchdog_counter + 1;
                IF l_watchdog_counter > g_watchdog_count_limit
                THEN
                    g_error := 'watchdog loop counter limit value reached [' || g_watchdog_count_limit || ']';
                    RAISE e_user_exception;
                END IF;
            END LOOP;
        
            -- no recurrence pattern defined (one-time execution)
        ELSIF rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none
        THEN
            -- ########################################
            -- ## ONE-TIME EXECUTION (NO RECURRENCE) ##
            -- ########################################
        
            g_error := 'process one-time execution (the start date)';
            pk_alertlog.log_debug(g_error, g_package_name);
            l_plan.extend;
            -- one-time executions cannot be overloaded by l_order_start_date
            l_plan(1) := t_rec_order_recurr_plan(rec_orcpl.id_order_recurr_plan, 1, rec_orcpl.start_date);
            l_flg_plan_end := TRUE; -- last execution for the entire plan was reached also
        
            -- invalid pattern
        ELSE
            -- ################################
            -- ## INVALID RECURRENCE PATTERN ##
            -- ################################
        
            g_error := 'invalid order plan found in order_recurr_plan table, where id_order_recurr_plan is [' ||
                       i_order_plan || ']';
            RAISE e_user_exception;
        
        END IF;
    
        -- create order plan collection, delimited by the desired plan interval
        g_error := 'create o_order_plan collection';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT t_rec_order_recurr_plan(id_order_recurrence_plan, exec_number, exec_timestamp)
          BULK COLLECT
          INTO o_order_plan
          FROM TABLE(CAST(l_plan AS t_tbl_order_recurr_plan)) plan
         WHERE plan.exec_timestamp >= l_order_plan_start_date
           AND (plan.exec_timestamp <= l_order_plan_end_date OR l_order_plan_end_date IS NULL)
         ORDER BY exec_number;
    
        -- check if  last execution for the entire plan was reached
        IF l_flg_plan_end
        THEN
            o_last_exec_reached := pk_alert_constant.g_yes;
        ELSE
            o_last_exec_reached := pk_alert_constant.g_no;
        END IF;
    
        -- log call for debug (comment this before versioning)
        --dbms_output.put_line('Log call id: ' || pk_alertlog.get_call_id());
    
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
    END get_order_recurr_plan_proc;

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
    ) RETURN BOOLEAN IS
        rec_orcpl               order_recurr_plan%ROWTYPE;
        l_order_start_date      order_recurr_plan.start_date%TYPE;
        l_plan                  t_tbl_order_recurr_plan := t_tbl_order_recurr_plan();
        l_plan_exec             PLS_INTEGER;
        l_plan_idx              PLS_INTEGER := 1;
        l_plan_next_exec_ts     TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_plan_start_date TIMESTAMP WITH LOCAL TIME ZONE := i_plan_start_date;
        l_order_plan_end_date   TIMESTAMP WITH LOCAL TIME ZONE := i_plan_end_date;
        l_order_day             TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_start_day       TIMESTAMP WITH LOCAL TIME ZONE;
        l_repeat_every          PLS_INTEGER;
        l_repeat_every_anchor   PLS_INTEGER;
        l_flg_last_exec         BOOLEAN;
        l_orcplt_exec           t_tbl_orcplt;
        l_orcplt_exec_nr        PLS_INTEGER;
        l_order_date_limit      TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_plan_end          BOOLEAN;
        l_watchdog_counter      PLS_INTEGER := 1;
    
        l_flg_has_exact_times VARCHAR2(1 CHAR);
    
    BEGIN
        -- get record from order_recurr_plan table
        g_error := 'get record from order_recurr_plan table, where id_order_recurr_plan is [' || i_order_plan || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT *
          INTO rec_orcpl
          FROM order_recurr_plan orcpl
         WHERE orcpl.id_order_recurr_plan = i_order_plan
           AND orcpl.flg_status = g_plan_status_final;
    
        -- validate and adjust plan interval according to the order recurrence plan
        IF NOT set_order_plan_interval(i_lang                   => i_lang,
                                       io_plan_start_date       => l_order_plan_start_date,
                                       io_plan_end_date         => l_order_plan_end_date,
                                       i_proc_from_day          => i_proc_from_day,
                                       i_proc_from_exec_nr      => i_proc_from_exec_nr,
                                       i_flg_validate_proc_from => i_flg_validate_proc_from,
                                       i_order_plan_record      => rec_orcpl,
                                       o_plan_exec_nr           => l_plan_exec,
                                       o_order_start_date       => l_order_start_date,
                                       o_order_date_limit       => l_order_date_limit,
                                       o_error                  => o_error)
        THEN
            g_error := 'error found while calling set_order_plan_interval function';
            RAISE e_user_exception;
        END IF;
    
        -- check if regular interval field is set
        IF rec_orcpl.regular_interval IS NOT NULL
        THEN
            -- #######################
            -- ## REGULAR INTERVALS ##
            -- #######################
        
            -- process the first execution
            g_error := 'process the first execution';
            pk_alertlog.log_debug(g_error, g_package_name);
            l_plan.extend;
            l_plan(l_plan_idx) := t_rec_order_recurr_plan(rec_orcpl.id_order_recurr_plan,
                                                          l_plan_exec,
                                                          l_order_start_date);
            g_error := 'execution number [' || l_plan_exec || '] processed successfully with [' || l_order_start_date ||
                       '] timestamp';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- anchor point (start the recurrence variables)
            l_plan_next_exec_ts   := l_order_start_date;
            l_order_day           := get_timestamp_day_tstz(i_lang, i_prof, l_order_start_date);
            l_order_start_day     := l_order_day;
            l_repeat_every_anchor := 0;
            LOOP
                -- calculate the next execution
                g_error := 'process the next execution';
                pk_alertlog.log_debug(g_error, g_package_name);
                l_plan_next_exec_ts := add_offset_to_tstz(i_offset    => rec_orcpl.regular_interval,
                                                          i_timestamp => l_plan_next_exec_ts,
                                                          i_unit      => rec_orcpl.id_unit_meas_regular_interval);
                -- process this execution using plan recurrence pattern and indicates if this is the last execution for the given plan interval
                IF NOT process_recurr_pattern_exec(i_lang                 => i_lang,
                                                   i_prof                 => i_prof,
                                                   i_rec_orcpl            => rec_orcpl,
                                                   io_repeat_every        => l_repeat_every,
                                                   io_repeat_every_anchor => l_repeat_every_anchor,
                                                   io_order_day           => l_order_day,
                                                   i_order_start_day      => l_order_start_day,
                                                   i_plan_next_exec_ts    => l_plan_next_exec_ts,
                                                   io_plan                => l_plan,
                                                   io_plan_exec           => l_plan_exec,
                                                   io_plan_idx            => l_plan_idx,
                                                   i_order_plan_end_date  => l_order_plan_end_date,
                                                   o_flg_last_exec        => l_flg_last_exec,
                                                   i_order_date_limit     => l_order_date_limit,
                                                   o_flg_plan_end         => l_flg_plan_end,
                                                   o_error                => o_error)
                THEN
                    g_error := 'error found while calling process_recurr_pattern_exec function for regular intervals frequency';
                    RAISE e_user_exception;
                END IF;
                -- evaluate if last execution was processed
                IF l_flg_last_exec
                THEN
                    EXIT; -- exit loop
                END IF;
                -- watchdog counter
                l_watchdog_counter := l_watchdog_counter + 1;
                IF l_watchdog_counter > g_watchdog_count_limit
                THEN
                    g_error := 'watchdog loop counter limit value reached [' || g_watchdog_count_limit || ']';
                    RAISE e_user_exception;
                END IF;
            END LOOP;
        
            -- check if daily executions field is set
        ELSIF rec_orcpl.daily_executions IS NOT NULL
              AND rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none
        THEN
            -- ######################
            -- ## DAILY EXECUTIONS ##
            -- ######################
        
            -- check if start date must be included as the first execution
            IF (rec_orcpl.flg_include_start_date_in_plan = pk_alert_constant.g_yes)
            THEN
                -- process the first execution
                g_error := 'process the first execution';
                pk_alertlog.log_debug(g_error, g_package_name);
                l_plan.extend;
                l_plan(l_plan_idx) := t_rec_order_recurr_plan(rec_orcpl.id_order_recurr_plan,
                                                              l_plan_exec,
                                                              l_order_start_date);
                g_error := 'execution number [' || l_plan_exec || '] processed successfully with [' ||
                           l_order_start_date || '] timestamp';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- prepare variables to process next execution
                l_plan_idx  := l_plan_idx + 1;
                l_plan_exec := l_plan_exec + 1;
            END IF;
        
            -- init order day
            l_order_day := get_timestamp_day_tstz(i_lang, i_prof, l_order_start_date);
            -- get exec times from order_recurr_plan_time table
            g_error := 'process records from order_recurr_plan_time table, where id_order_recurr_plan is [' ||
                       i_order_plan || ']';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF NOT get_daily_exec_time_plan(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_order_plan            => i_order_plan,
                                            i_daily_exec_nr         => rec_orcpl.daily_executions,
                                            i_default_exec_interval => l_order_start_date - l_order_day,
                                            o_orcplt_exec           => l_orcplt_exec,
                                            o_flg_has_exact_times   => l_flg_has_exact_times,
                                            o_error                 => o_error)
            THEN
                g_error := 'error found while calling get_daily_exec_time_plan function';
                RAISE e_user_exception;
            END IF;
            -- now l_orcplt_exec collection has the daily execution times.
            -- when looking to this array, the records are always sorted from the beggining to the end of each day
            -- position (1): first execution of the day, position (2): second execution of the day, and so on...
        
            -- find daily execution number for the start day
            l_orcplt_exec_nr := get_daily_exec_number(i_start_date  => l_order_start_date,
                                                      i_order_day   => l_order_day,
                                                      i_orcplt_exec => l_orcplt_exec);
            -- if no exec time was found, then use the 1st exec time of the next day
            IF l_orcplt_exec_nr = 0
            THEN
                l_order_day      := trunc(l_order_day, 'DD') + 1; -- because the next exec time will occur only in the next day
                l_orcplt_exec_nr := 1; -- reset exec time plan for the 1st exec time number
            END IF;
            l_order_start_day     := l_order_day;
            l_repeat_every_anchor := 0;
        
            -- get start execution timestamp
            l_plan_next_exec_ts := add_offset_to_tstz(i_offset    => l_orcplt_exec(l_orcplt_exec_nr).exec_time_offset,
                                                      i_timestamp => l_order_day + l_orcplt_exec(l_orcplt_exec_nr).exec_time,
                                                      i_unit      => l_orcplt_exec(l_orcplt_exec_nr).id_unit_meas_exec_time_offset);
            -- process the first execution
            g_error := 'process the first execution';
            pk_alertlog.log_debug(g_error, g_package_name);
            l_plan.extend;
            l_plan(l_plan_idx) := t_rec_order_recurr_plan(rec_orcpl.id_order_recurr_plan,
                                                          l_plan_exec,
                                                          l_plan_next_exec_ts);
            g_error := 'execution number [' || l_plan_exec || '] processed successfully with [' || l_plan_next_exec_ts ||
                       '] timestamp';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            LOOP
                -- process next daily execution number
                l_orcplt_exec_nr := l_orcplt_exec_nr + 1;
                IF l_orcplt_exec_nr > rec_orcpl.daily_executions
                THEN
                    -- jump to the 1st exec time of the next day by assigning l_orcplt_exec_nr to zero
                    l_orcplt_exec_nr := 0; -- 1st exec time of the next day (get_next_daily_exec_time can handle this value)
                END IF;
                -- calculate the next execution
                g_error := 'process the next execution';
                pk_alertlog.log_debug(g_error, g_package_name);
                l_plan_next_exec_ts := get_next_daily_exec_time(i_order_day    => get_timestamp_day_tstz(i_lang,
                                                                                                         i_prof,
                                                                                                         l_plan_next_exec_ts),
                                                                i_orcplt_exec  => l_orcplt_exec,
                                                                io_exec_number => l_orcplt_exec_nr); -- execution number will be updated also, if needed
                -- process this execution using plan recurrence pattern and indicates if this is the last execution for the given plan interval
                IF NOT process_recurr_pattern_exec(i_lang                 => i_lang,
                                                   i_prof                 => i_prof,
                                                   i_rec_orcpl            => rec_orcpl,
                                                   io_repeat_every        => l_repeat_every,
                                                   io_repeat_every_anchor => l_repeat_every_anchor,
                                                   io_order_day           => l_order_day,
                                                   i_order_start_day      => l_order_start_day,
                                                   i_plan_next_exec_ts    => l_plan_next_exec_ts,
                                                   io_plan                => l_plan,
                                                   io_plan_exec           => l_plan_exec,
                                                   io_plan_idx            => l_plan_idx,
                                                   i_order_plan_end_date  => l_order_plan_end_date,
                                                   o_flg_last_exec        => l_flg_last_exec,
                                                   i_order_date_limit     => l_order_date_limit,
                                                   o_flg_plan_end         => l_flg_plan_end,
                                                   o_error                => o_error)
                THEN
                    g_error := 'error found while calling process_recurr_pattern_exec function for daily executions frequency';
                    RAISE e_user_exception;
                END IF;
                -- evaluate if last execution was processed
                IF l_flg_last_exec
                THEN
                    EXIT; -- exit loop
                END IF;
                -- watchdog counter
                l_watchdog_counter := l_watchdog_counter + 1;
                IF l_watchdog_counter > g_watchdog_count_limit
                THEN
                    g_error := 'watchdog loop counter limit value reached [' || g_watchdog_count_limit || ']';
                    RAISE e_user_exception;
                END IF;
            END LOOP;
        
            -- no recurrence pattern defined (one-time execution)
        ELSIF rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none
        THEN
            -- ########################################
            -- ## ONE-TIME EXECUTION (NO RECURRENCE) ##
            -- ########################################
        
            g_error := 'process one-time execution (the start date)';
            pk_alertlog.log_debug(g_error, g_package_name);
            l_plan.extend;
            -- one-time executions cannot be overloaded by l_order_start_date
            l_plan(1) := t_rec_order_recurr_plan(rec_orcpl.id_order_recurr_plan, 1, rec_orcpl.start_date);
            l_flg_plan_end := TRUE; -- last execution for the entire plan was reached also
        
            -- invalid pattern
        ELSE
            -- ################################
            -- ## INVALID RECURRENCE PATTERN ##
            -- ################################
        
            g_error := 'invalid order plan found in order_recurr_plan table, where id_order_recurr_plan is [' ||
                       i_order_plan || ']';
            RAISE e_user_exception;
        
        END IF;
    
        -- create order plan collection, delimited by the desired plan interval
        g_error := 'create o_order_plan collection';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT t_rec_order_recurr_plan(id_order_recurrence_plan, exec_number, exec_timestamp)
          BULK COLLECT
          INTO o_order_plan
          FROM TABLE(CAST(l_plan AS t_tbl_order_recurr_plan)) plan
         WHERE ((plan.exec_timestamp >= (l_order_plan_start_date - numtodsinterval(1, 'MINUTE')) AND
               plan.exec_number = 1) OR
               ((plan.exec_timestamp >= (l_order_plan_start_date - numtodsinterval(1, 'MINUTE')) AND
               plan.exec_number > 1)))
           AND (plan.exec_timestamp <= (l_order_plan_end_date + numtodsinterval(1, 'MINUTE')) OR
               l_order_plan_end_date IS NULL)
         ORDER BY exec_number;
    
        -- check if  last execution for the entire plan was reached
        IF l_flg_plan_end
        THEN
            o_last_exec_reached := pk_alert_constant.g_yes;
        ELSE
            o_last_exec_reached := pk_alert_constant.g_no;
        END IF;
    
        -- log call for debug (comment this before versioning)
        --dbms_output.put_line('Log call id: ' || pk_alertlog.get_call_id());
    
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
    * get order recurrence option execution times
    *
    * @param       i_lang                     preferred language id
    * @param       i_prof                     professional structure
    * @param       i_order_option             the order recurrence option
    * @param       o_order_option_exec_time   all exec times for all options related with i_order_option
    * @param       o_error                    error structure for exception handling
    *
    * @return      boolean                    true on success, otherwise false
    *
    * @author                                 Carlos Loureiro
    * @since                                  21-APR-2011
    ********************************************************************************************/
    FUNCTION get_order_option_executions
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_option           IN order_recurr_option.id_order_recurr_option%TYPE,
        o_order_option_exec_time OUT t_tbl_orcotmsi,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_recurr_options table_number;
    BEGIN
        -- get all child options based in given order option
        g_error := 'get all child options in order_recurr_option_grp table for [' || i_order_option || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT orcog.id_order_recurr_option_child
          BULK COLLECT
          INTO l_order_recurr_options
          FROM order_recurr_option_grp orcog
         START WITH orcog.id_order_recurr_option_parent = i_order_option
        CONNECT BY PRIOR orcog.id_order_recurr_option_child = orcog.id_order_recurr_option_parent;
        -- add main option into the collection
        l_order_recurr_options.extend;
        l_order_recurr_options(l_order_recurr_options.count) := i_order_option;
        -- get exec times for each one of the options processed in previous block
        IF NOT get_recurr_option_time(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_order_recurr_option => l_order_recurr_options,
                                      o_order_recurr_time   => o_order_option_exec_time,
                                      o_error               => o_error)
        THEN
            g_error := 'error found while calling get_recurr_option_time function';
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
                                              'GET_ORDER_OPTION_EXECUTIONS',
                                              o_error);
            RETURN FALSE;
    END get_order_option_executions;

    /********************************************************************************************
    * check end date setting of an order recurrence plan
    *
    * @param       i_order_recurr_plan        order recurrence plan id
    * @param       o_error                    error structure for exception handling
    *
    * @return      varchar2                   end date setting value
    *
    * @author                                 Tiago Silva
    * @since                                  28-APR-2011
    ********************************************************************************************/
    FUNCTION check_end_date_set(i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE)
        RETURN order_recurr_option.flg_set_end_date%TYPE IS
    
        l_end_date_set order_recurr_option.flg_set_end_date%TYPE;
    
    BEGIN
    
        g_error := 'check end date setting of the order recurrence plan';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT orco.flg_set_end_date
          INTO l_end_date_set
          FROM order_recurr_plan orcpl
         INNER JOIN order_recurr_option orco
            ON (orcpl.id_order_recurr_option = orco.id_order_recurr_option)
         WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan;
    
        RETURN l_end_date_set;
    
    END check_end_date_set;

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
    ) RETURN BOOLEAN IS
        CURSOR c_order_recurr_option(x_id_order_recurr_plan_id IN order_recurr_plan.id_order_recurr_plan%TYPE) IS
            SELECT id_order_recurr_option
              FROM order_recurr_plan
             WHERE id_order_recurr_plan = x_id_order_recurr_plan_id;
    
        rec_orcpl             order_recurr_plan%ROWTYPE;
        l_plan                t_tbl_order_recurr_plan;
        l_plan_exec           PLS_INTEGER := 1;
        l_plan_idx            PLS_INTEGER := 1;
        l_plan_next_exec_ts   TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_day           TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_day_f         order_recurr_plan.start_date%TYPE;
        l_order_day_p         order_recurr_plan.start_date%TYPE;
        l_order_start_day     TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_end_date      TIMESTAMP WITH LOCAL TIME ZONE;
        l_repeat_every        PLS_INTEGER;
        l_repeat_every_anchor PLS_INTEGER;
        l_flg_last_exec       BOOLEAN;
        l_orcplt_exec         t_tbl_orcplt;
        l_orcplt_exec_nr      PLS_INTEGER;
        l_flg_plan_end        BOOLEAN;
        l_watchdog_counter    PLS_INTEGER := 1;
    
        l_flg_has_exact_times VARCHAR2(1 CHAR);
    
        l_t_tbl_orcotmsi t_tbl_orcotmsi;
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        -- get record from order_recurr_plan table
        g_error := 'get record from order_recurr_plan table, where id_order_recurr_plan is [' || i_order_plan || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT *
          INTO rec_orcpl
          FROM order_recurr_plan orcpl
         WHERE orcpl.id_order_recurr_plan = i_order_plan;
        -- the following line code is commented to allow instructions in non-temporary plans
        -- AND orcpl.flg_status = g_plan_status_temp;
    
        -- check if regular interval field is set
        IF rec_orcpl.regular_interval IS NOT NULL
        THEN
            -- #######################
            -- ## REGULAR INTERVALS ##
            -- #######################
        
            -- anchor point (start the recurrence variables)
            l_plan_next_exec_ts   := rec_orcpl.start_date;
            l_order_day           := get_timestamp_day_tstz(i_lang, i_prof, rec_orcpl.start_date);
            l_order_start_day     := l_order_day;
            l_repeat_every_anchor := 0;
        
            -- create plan's 1st execution (end date by duration fix)
            l_plan := t_tbl_order_recurr_plan(t_rec_order_recurr_plan(i_order_plan, 1, rec_orcpl.start_date));
        
            -- process output variables
            g_error := 'process o_start_date, o_occurrences, o_duration and o_unit_meas_duration';
            pk_alertlog.log_debug(g_error, g_package_name);
            o_start_date         := l_plan_next_exec_ts; -- the first execution is the order plan start date
            o_occurrences        := rec_orcpl.occurrences;
            o_duration           := rec_orcpl.duration;
            o_unit_meas_duration := rec_orcpl.id_unit_meas_duration;
            -- if we have a recurrence pattern with an end date
            IF rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none
               AND rec_orcpl.flg_end_by != g_flg_end_by_no_end
            THEN
                o_end_date := o_start_date; -- set end date = start date as the starting point (the end date isn't defined if we have a recurrence without end limit)
            END IF;
            -- if the end date is defined
            IF rec_orcpl.end_date IS NOT NULL
            THEN
                -- if order plan end date is not null, limit the processing to this end date
                l_order_end_date := rec_orcpl.end_date;
            ELSIF rec_orcpl.flg_end_by = g_flg_end_by_duration
            THEN
                -- if order plan end date is null, but it has a defined maximum duration, process the end date
                l_order_end_date := add_offset_to_tstz(i_offset    => rec_orcpl.duration,
                                                       i_timestamp => o_start_date,
                                                       i_unit      => rec_orcpl.id_unit_meas_duration);
            END IF;
        
            -- the next loop will only process if the end date value calculation is possible
            IF rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none
               OR (rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none AND
               rec_orcpl.flg_end_by != g_flg_end_by_no_end)
            THEN
                LOOP
                    -- calculate the next execution
                    g_error := 'process the next execution';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    l_plan_next_exec_ts := add_offset_to_tstz(i_offset    => rec_orcpl.regular_interval,
                                                              i_timestamp => l_plan_next_exec_ts,
                                                              i_unit      => rec_orcpl.id_unit_meas_regular_interval);
                    -- process this execution using plan recurrence pattern and indicates if this is the last execution for the given plan interval
                    IF NOT process_recurr_pattern_exec(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_rec_orcpl            => rec_orcpl,
                                                       io_repeat_every        => l_repeat_every,
                                                       io_repeat_every_anchor => l_repeat_every_anchor,
                                                       io_order_day           => l_order_day,
                                                       i_order_start_day      => l_order_start_day,
                                                       i_plan_next_exec_ts    => l_plan_next_exec_ts,
                                                       io_plan                => l_plan,
                                                       io_plan_exec           => l_plan_exec,
                                                       io_plan_idx            => l_plan_idx,
                                                       i_order_plan_end_date  => l_order_end_date,
                                                       o_flg_last_exec        => l_flg_last_exec,
                                                       i_order_date_limit     => NULL,
                                                       o_flg_plan_end         => l_flg_plan_end,
                                                       o_error                => o_error)
                    THEN
                        g_error := 'error found while calling process_recurr_pattern_exec function for regular intervals frequency';
                        RAISE e_user_exception;
                    END IF;
                    -- evaluate if last execution was processed
                    IF l_flg_last_exec
                    THEN
                        IF (rec_orcpl.flg_end_by = g_flg_end_by_occurrences AND rec_orcpl.flg_end_by IS NOT NULL) -- if plan is limited in the number of occurrences
                           AND l_flg_plan_end -- and if plan ended
                           AND rec_orcpl.occurrences > 1 -- and when then number of occurrences is 1, the end date equals the start date
                        THEN
                            o_end_date := l_plan_next_exec_ts;
                        ELSIF rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none
                        THEN
                            o_end_date := l_order_end_date;
                        END IF;
                        EXIT; -- exit loop (o_end_date will have the last's execution timestamp, assigned in the previous loop)
                    ELSE
                        o_end_date := l_plan_next_exec_ts;
                    END IF;
                    -- watchdog counter
                    l_watchdog_counter := l_watchdog_counter + 1;
                    IF l_watchdog_counter > g_watchdog_count_limit
                    THEN
                        g_error := 'watchdog loop counter limit value reached [' || g_watchdog_count_limit || ']';
                        RAISE e_user_exception;
                    END IF;
                END LOOP;
            END IF;
        
            -- check if daily executions field is set
        ELSIF rec_orcpl.daily_executions IS NOT NULL
              AND rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none
        THEN
            -- ######################
            -- ## DAILY EXECUTIONS ##
            -- ######################
        
            -- init order day
            l_order_day := get_timestamp_day_tstz(i_lang, i_prof, rec_orcpl.start_date);
            -- get exec times from order_recurr_plan_time table
            g_error := 'process records from order_recurr_plan_time table, where id_order_recurr_plan is [' ||
                       i_order_plan || ']';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF NOT get_daily_exec_time_plan(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_order_plan            => i_order_plan,
                                            i_daily_exec_nr         => rec_orcpl.daily_executions,
                                            i_default_exec_interval => rec_orcpl.start_date - l_order_day,
                                            o_orcplt_exec           => l_orcplt_exec,
                                            o_flg_has_exact_times   => l_flg_has_exact_times,
                                            o_error                 => o_error)
            THEN
                g_error := 'error found while calling get_daily_exec_time_plan function';
                RAISE e_user_exception;
            END IF;
        
            IF (rec_orcpl.flg_include_start_date_in_plan = pk_alert_constant.g_no)
            THEN
                -- now l_orcplt_exec collection has the daily execution times.
                -- when looking to this array, the records are always sorted from the beggining to the end of each day
                -- position (1): first execution of the day, position (2): second execution of the day, and so on...
            
                -- find daily execution number for the start day
                l_orcplt_exec_nr := get_daily_exec_number(i_start_date  => rec_orcpl.start_date,
                                                          i_order_day   => l_order_day,
                                                          i_orcplt_exec => l_orcplt_exec);
                -- if no exec time was found, then use the 1st exec time of the next day
                IF l_orcplt_exec_nr = 0
                THEN
                    l_order_day      := l_order_day + 1; -- because the next exec time will occur only in the next day
                    l_orcplt_exec_nr := 1; -- reset exec time plan for the 1st exec time number
                END IF;
            
                -- get start execution timestamp
                l_plan_next_exec_ts := add_offset_to_tstz(i_offset    => l_orcplt_exec(l_orcplt_exec_nr).exec_time_offset,
                                                          i_timestamp => l_order_day + l_orcplt_exec(l_orcplt_exec_nr).exec_time,
                                                          i_unit      => l_orcplt_exec(l_orcplt_exec_nr).id_unit_meas_exec_time_offset);
            
                -- create plan's 1st execution (end date by duration fix)
                l_plan := t_tbl_order_recurr_plan(t_rec_order_recurr_plan(i_order_plan, 1, l_plan_next_exec_ts));
            
            ELSE
            
                l_orcplt_exec_nr    := 0;
                l_plan_next_exec_ts := rec_orcpl.start_date;
            
                -- create plan's 1st execution (end date by duration fix)
                l_plan := t_tbl_order_recurr_plan(t_rec_order_recurr_plan(i_order_plan, 1, rec_orcpl.start_date));
            
            END IF;
        
            l_order_start_day     := l_order_day;
            l_repeat_every_anchor := 0;
        
            -- process output variables
            g_error := 'process o_start_date, o_occurrences, o_duration and o_unit_meas_duration';
            pk_alertlog.log_debug(g_error, g_package_name);
            o_start_date         := l_plan_next_exec_ts; -- the first execution is the order plan start date
            o_occurrences        := rec_orcpl.occurrences;
            o_duration           := rec_orcpl.duration;
            o_unit_meas_duration := rec_orcpl.id_unit_meas_duration;
            -- if we have a recurrence pattern with an end date
            IF rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none
               AND rec_orcpl.flg_end_by != g_flg_end_by_no_end
            THEN
                o_end_date := o_start_date; -- set end date = start date as the starting point (the end date isn't defined if we have a recurrence without end limit)
            END IF;
            -- if the end date is defined
            IF rec_orcpl.end_date IS NOT NULL
            THEN
                -- if order plan end date is not null, limit the processing to this end date
                l_order_end_date := rec_orcpl.end_date;
            ELSIF rec_orcpl.flg_end_by = g_flg_end_by_duration
            THEN
                -- if order plan end date is null, but it has a defined maximum duration, process the end date
                l_order_end_date := add_offset_to_tstz(i_offset    => rec_orcpl.duration,
                                                       i_timestamp => o_start_date,
                                                       i_unit      => rec_orcpl.id_unit_meas_duration);
            END IF;
        
            -- the next loop will only process if the end date value calculation, if possible
            IF rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none
               OR (rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none AND
               rec_orcpl.flg_end_by != g_flg_end_by_no_end)
            THEN
                LOOP
                    -- process next daily execution number
                    l_orcplt_exec_nr := l_orcplt_exec_nr + 1;
                    IF l_orcplt_exec_nr > rec_orcpl.daily_executions
                    THEN
                        -- jump to the 1st exec time of the next day by assigning l_orcplt_exec_nr to zero
                        l_orcplt_exec_nr := 0; -- 1st exec time of the next day (get_next_daily_exec_time can handle this value)
                    END IF;
                    -- calculate the next execution
                    g_error := 'process the next execution';
                    pk_alertlog.log_debug(g_error, g_package_name);
                    l_plan_next_exec_ts := get_next_daily_exec_time(i_order_day    => get_timestamp_day_tstz(i_lang,
                                                                                                             i_prof,
                                                                                                             l_plan_next_exec_ts),
                                                                    i_orcplt_exec  => l_orcplt_exec,
                                                                    io_exec_number => l_orcplt_exec_nr); -- execution number will be updated also, if needed
                    -- process this execution using plan recurrence pattern and indicates if this is the last execution for the given plan interval
                    IF NOT process_recurr_pattern_exec(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_rec_orcpl            => rec_orcpl,
                                                       io_repeat_every        => l_repeat_every,
                                                       io_repeat_every_anchor => l_repeat_every_anchor,
                                                       io_order_day           => l_order_day,
                                                       i_order_start_day      => l_order_start_day,
                                                       i_plan_next_exec_ts    => l_plan_next_exec_ts,
                                                       io_plan                => l_plan,
                                                       io_plan_exec           => l_plan_exec,
                                                       io_plan_idx            => l_plan_idx,
                                                       i_order_plan_end_date  => l_order_end_date,
                                                       o_flg_last_exec        => l_flg_last_exec,
                                                       i_order_date_limit     => NULL,
                                                       o_flg_plan_end         => l_flg_plan_end,
                                                       o_error                => o_error)
                    THEN
                        g_error := 'error found while calling process_recurr_pattern_exec function for daily executions frequency';
                        RAISE e_user_exception;
                    END IF;
                    -- evaluate if last execution was processed
                    IF l_flg_last_exec
                    THEN
                        IF ((rec_orcpl.flg_end_by = g_flg_end_by_occurrences AND rec_orcpl.flg_end_by IS NOT NULL) -- if plan is limited in the number of occurrences
                           AND l_flg_plan_end -- and if plan ended
                           AND rec_orcpl.occurrences > 1) -- and when then number of occurrences is 1, the end date equals the start date
                           OR l_flg_has_exact_times = pk_alert_constant.g_no
                        THEN
                            o_end_date := l_plan_next_exec_ts;
                            --o_end_date := l_order_end_date;
                        
                        ELSIF rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none
                        THEN
                            o_end_date := NULL;
                        END IF;
                        EXIT; -- exit loop (o_end_date will have the last's execution timestamp, assigned in the previous loop)
                    ELSE
                        o_end_date := l_plan_next_exec_ts;
                    END IF;
                    -- watchdog counter
                    l_watchdog_counter := l_watchdog_counter + 1;
                    IF l_watchdog_counter > g_watchdog_count_limit
                    THEN
                        g_error := 'watchdog loop counter limit value reached [' || g_watchdog_count_limit || ']';
                        RAISE e_user_exception;
                    END IF;
                END LOOP;
            END IF;
        
            -- no recurrence pattern defined (one-time execution)
        ELSIF rec_orcpl.flg_recurr_pattern = g_flg_recurr_pattern_none
              OR rec_orcpl.id_order_recurr_option = g_order_recurr_option_no_sched
        THEN
            -- ########################################
            -- ## ONE-TIME EXECUTION (NO RECURRENCE) ##
            -- ########################################
        
            -- check if "no-sched" option was selected to disable number of occurrences
            IF rec_orcpl.id_order_recurr_option = g_order_recurr_option_no_sched
            THEN
                g_error := 'process "no-sched" execution';
                pk_alertlog.log_debug(g_error, g_package_name);
                o_occurrences := NULL;
            ELSE
                -- assume this process has only one execution, with i_start_date timestamp
                g_error := 'process "one-time" execution (the start date)';
                pk_alertlog.log_debug(g_error, g_package_name);
                o_occurrences := 1;
            END IF;
        
            BEGIN
                OPEN c_order_recurr_option(i_order_plan);
                FETCH c_order_recurr_option
                    INTO o_order_recurr_option;
                CLOSE c_order_recurr_option;
            
                IF NOT get_recurr_option_time(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_order_recurr_option => table_number(o_order_recurr_option),
                                              o_order_recurr_time   => l_t_tbl_orcotmsi,
                                              o_error               => o_error)
                THEN
                    RAISE e_user_exception;
                END IF;
            
                IF l_t_tbl_orcotmsi IS NOT NULL
                   AND l_t_tbl_orcotmsi.count > 0
                THEN
                
                    l_order_day   := get_timestamp_day_tstz(i_lang, i_prof, rec_orcpl.start_date);
                    l_order_day_f := add_offset_to_tstz(i_offset    => l_t_tbl_orcotmsi(1).exec_time_offset,
                                                        i_timestamp => l_order_day + l_t_tbl_orcotmsi(1).exec_time,
                                                        i_unit      => l_t_tbl_orcotmsi(1).id_unit_meas_exec_time_offset);
                    IF l_order_day_f > l_sysdate
                    THEN
                        o_start_date := l_order_day_f;
                    ELSE
                        o_start_date := add_offset_to_tstz(i_offset    => 24,
                                                           i_timestamp => l_order_day + l_t_tbl_orcotmsi(1).exec_time,
                                                           i_unit      => g_unit_measure_hour);
                    END IF;
                
                    --o_start_date := l_t_tbl_orcotmsi(1).exec_time;
                ELSE
                    o_start_date := rec_orcpl.start_date;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    o_start_date := rec_orcpl.start_date;
            END;
        
            -- invalid pattern
        ELSE
            -- ################################
            -- ## INVALID RECURRENCE PATTERN ##
            -- ################################
        
            g_error := 'invalid order plan found in order_recurr_plan table, where id_order_recurr_plan is [' ||
                       i_order_plan || ']';
            RAISE e_user_exception;
        
        END IF;
    
        -- calculate last execution timestamp when duration field is used (end date by duration fix)
        IF rec_orcpl.flg_end_by = g_flg_end_by_duration
        THEN
            -- get order end timestamp by given duration
            l_order_end_date := add_offset_to_tstz(i_offset    => rec_orcpl.duration,
                                                   i_timestamp => o_start_date,
                                                   i_unit      => rec_orcpl.id_unit_meas_duration);
            -- get last execution timestamp
            BEGIN
                SELECT MAX(exec_timestamp)
                  INTO o_end_date
                  FROM TABLE(CAST(l_plan AS t_tbl_order_recurr_plan))
                 WHERE exec_timestamp <= l_order_end_date;
            EXCEPTION
                WHEN no_data_found THEN
                    o_end_date := rec_orcpl.start_date;
            END;
        END IF;
    
        -- assign remain plan/option variables
        o_order_recurr_desc   := get_order_recurr_pfreq_desc(i_lang, i_prof, i_order_plan);
        o_flg_end_by_editable := check_end_date_set(i_order_plan);
    
        OPEN c_order_recurr_option(i_order_plan);
        FETCH c_order_recurr_option
            INTO o_order_recurr_option;
        CLOSE c_order_recurr_option;
    
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
    * get available order recurrence options for a given order recurrence area
    *
    * @param       i_lang                    preferred language id
    * @param       i_prof                    professional structure
    * @param       i_order_recurr_area       order recurrence area internal name
    * @param       i_flg_selection_domain    flag that indicates the selection domain of the order recurrence options
    * @param       o_order_recurr_option     array of order recurrence times
    * @param       o_error                   error structure for exception handling
    *
    * @value       i_flg_selection_domain    {*} 'M' most frequent recurrences domain
    *                                        {*} 'P' predefined time schedules domain
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 20-APR-2011
    ********************************************************************************************/
    FUNCTION get_avail_order_recurr_options
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_recurr_area    IN order_recurr_area.internal_name%TYPE,
        i_flg_selection_domain IN order_recurr_option.flg_selection_domain%TYPE,
        o_order_recurr_option  OUT t_tbl_orcomsi,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        -- get institution market
        l_id_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        -- get professional profile template
        l_id_prof_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_id_order_recurr_area order_recurr_area.id_order_recurr_area%TYPE;
    BEGIN
    
        g_error := 'get order recurrence area id';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get order recurrence area id
        SELECT orca.id_order_recurr_area
          INTO l_id_order_recurr_area
          FROM order_recurr_area orca
         WHERE orca.internal_name = i_order_recurr_area;
    
        g_error := 'get o_order_recurr_option array data';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT t_rec_orcomsi(option_avail.id_order_recurr_option,
                             l_id_order_recurr_area,
                             option_avail.rank,
                             option_avail.flg_default)
          BULK COLLECT
          INTO o_order_recurr_option
          FROM (SELECT DISTINCT first_value(orcomsi.id_order_recurr_option) over(PARTITION BY orcomsi.id_order_recurr_option ORDER BY orcomsi.id_institution DESC, orcomsi.id_market DESC, orcomsi.id_software DESC, orcomsi.id_profile_template DESC) AS id_order_recurr_option,
                                first_value(orcomsi.rank) over(PARTITION BY orcomsi.id_order_recurr_option ORDER BY orcomsi.id_institution DESC, orcomsi.id_market DESC, orcomsi.id_software DESC, orcomsi.id_profile_template DESC) AS rank,
                                first_value(orcomsi.flg_default) over(PARTITION BY orcomsi.id_order_recurr_option ORDER BY orcomsi.id_institution DESC, orcomsi.id_market DESC, orcomsi.id_software DESC, orcomsi.id_profile_template DESC) AS flg_default,
                                first_value(orcomsi.flg_available) over(PARTITION BY orcomsi.id_order_recurr_option ORDER BY orcomsi.id_institution DESC, orcomsi.id_market DESC, orcomsi.id_software DESC, orcomsi.id_profile_template DESC) AS flg_available
                  FROM order_recurr_option_msi orcomsi
                 WHERE orcomsi.id_order_recurr_area = l_id_order_recurr_area
                   AND orcomsi.id_order_recurr_option IN
                       (SELECT orco.id_order_recurr_option
                          FROM order_recurr_option orco
                         WHERE orco.flg_selection_domain IN (g_flg_select_dom_both, i_flg_selection_domain))
                   AND orcomsi.id_market IN (l_id_market, pk_alert_constant.g_id_market_all)
                   AND orcomsi.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND orcomsi.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                   AND orcomsi.id_profile_template IN
                       (l_id_prof_profile_template, pk_alert_constant.g_profile_template_all)) option_avail
         WHERE option_avail.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_AVAIL_ORDER_RECURR_OPTIONS',
                                              o_error);
            RETURN FALSE;
    END get_avail_order_recurr_options;

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
    ) RETURN BOOLEAN IS
    
        l_avail_order_recurr_options t_tbl_orcomsi;
    
    BEGIN
    
        g_error := 'call get_avail_order_recurr_options function';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT get_avail_order_recurr_options(i_lang                 => i_lang,
                                              i_prof                 => i_prof,
                                              i_order_recurr_area    => i_order_recurr_area,
                                              i_flg_selection_domain => g_flg_select_dom_order_recurr,
                                              o_order_recurr_option  => l_avail_order_recurr_options,
                                              o_error                => o_error)
        THEN
            g_error := 'error found while calling get_avail_order_recurr_options function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'get default order recurrence option';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        BEGIN
            SELECT id_order_recurr_option
              INTO o_id_order_recurr_option
              FROM (SELECT /*+OPT_ESTIMATE (table avail_orco rows=1)*/
                     orco.id_order_recurr_option
                      FROM order_recurr_option orco
                     INNER JOIN TABLE(CAST(l_avail_order_recurr_options AS t_tbl_orcomsi)) avail_orco
                        ON (orco.id_order_recurr_option = avail_orco.id_order_recurr_option)
                     WHERE avail_orco.flg_default = pk_alert_constant.g_yes
                       AND orco.flg_selection_domain IN (g_flg_select_dom_both, g_flg_select_dom_order_recurr)
                     ORDER BY avail_orco.rank)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_id_order_recurr_option := 0;
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
                                              'GET_DEF_ORDER_RECURR_OPTION',
                                              o_error);
        
            RETURN FALSE;
    END get_def_order_recurr_option;

    /********************************************************************************************
    * check order recurrence integrity constraint
    *
    * @param       i_order_recurrence_plan   order recurrence plan ID
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 15-APR-2011
    ********************************************************************************************/
    FUNCTION check_orcpl_integrity_constr(i_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE) RETURN BOOLEAN IS
    
        CURSOR c_order_recurr_plan IS
            SELECT regular_interval,
                   id_unit_meas_regular_interval,
                   daily_executions,
                   flg_recurr_pattern,
                   repeat_every,
                   flg_repeat_by,
                   occurrences,
                   duration,
                   id_unit_meas_duration
              FROM order_recurr_plan orcp
             WHERE orcp.id_order_recurr_plan = i_order_recurr_plan;
    
        l_num_plan_patterns        PLS_INTEGER;
        l_num_plan_patterns_wd     PLS_INTEGER;
        l_num_plan_patterns_w      PLS_INTEGER;
        l_num_plan_patterns_m      PLS_INTEGER;
        l_num_plan_patterns_md     PLS_INTEGER;
        l_num_plan_patterns_w_md_m PLS_INTEGER;
        l_num_plan_patterns_m_md   PLS_INTEGER;
        l_num_plan_patterns_wd_w_m PLS_INTEGER;
        l_num_plan_patterns_wd_w   PLS_INTEGER;
    
        l_order_recurr_plan c_order_recurr_plan%ROWTYPE;
    
    BEGIN
    
        -- get order recurrence plan parameters
        OPEN c_order_recurr_plan;
        FETCH c_order_recurr_plan
            INTO l_order_recurr_plan;
        CLOSE c_order_recurr_plan;
    
        -- get number of order recurrence plan patterns
        SELECT COUNT(1)
          INTO l_num_plan_patterns
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan;
    
        -- #1 "regular interval or daily executions" order plan rule exception
        IF NOT
            ((l_order_recurr_plan.regular_interval IS NOT NULL AND
            l_order_recurr_plan.id_unit_meas_regular_interval IS NOT NULL AND
            l_order_recurr_plan.daily_executions IS NULL AND l_num_plan_patterns = 0) OR
            (l_order_recurr_plan.regular_interval IS NULL AND l_order_recurr_plan.id_unit_meas_regular_interval IS NULL AND
            l_order_recurr_plan.daily_executions IS NOT NULL AND
            l_order_recurr_plan.daily_executions = l_num_plan_patterns))
        THEN
            g_error := '"regular interval or daily executions" order plan rule exception';
            RAISE e_user_exception;
        END IF;
    
        -- #2 "recurrence pattern" order plan rule exception
        IF (l_order_recurr_plan.flg_recurr_pattern = '0' AND
           (l_order_recurr_plan.repeat_every IS NOT NULL OR l_order_recurr_plan.flg_repeat_by IS NOT NULL OR
           l_order_recurr_plan.occurrences != 0 OR l_order_recurr_plan.duration IS NOT NULL OR
           l_order_recurr_plan.id_unit_meas_duration IS NOT NULL OR l_num_plan_patterns != 0))
        THEN
            g_error := '"recurrence pattern" order plan rule exception';
            RAISE e_user_exception;
        END IF;
    
        -- #3 "daily recurrence pattern" order plan rule exception
        IF (l_order_recurr_plan.flg_recurr_pattern = 'D' AND
           (l_order_recurr_plan.repeat_every IS NULL OR l_order_recurr_plan.flg_repeat_by IS NOT NULL OR
           l_num_plan_patterns != 0))
        THEN
            g_error := '"daily recurrence pattern" order plan rule exception';
            RAISE e_user_exception;
        END IF;
    
        -- get number of plan patterns that have defined values for week day field
        SELECT COUNT(1)
          INTO l_num_plan_patterns_wd
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
           AND orcplp.flg_week_day IS NOT NULL;
    
        -- get number of plan patterns that have defined values for week, month day or month fields
        SELECT COUNT(1)
          INTO l_num_plan_patterns_w_md_m
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
           AND (orcplp.flg_week IS NOT NULL OR orcplp.month_day IS NOT NULL OR orcplp.month IS NOT NULL);
    
        -- #4 "weekly recurrence pattern" order plan rule exception
        IF (l_order_recurr_plan.flg_recurr_pattern = 'W' AND
           (l_order_recurr_plan.repeat_every IS NULL OR l_order_recurr_plan.flg_repeat_by IS NOT NULL OR
           l_num_plan_patterns_wd = 0 OR l_num_plan_patterns_w_md_m != 0))
        THEN
            g_error := '"weekly recurrence pattern" order plan rule exception';
            RAISE e_user_exception;
        END IF;
    
        -- get number of plan patterns that have defined values for week field
        SELECT COUNT(1)
          INTO l_num_plan_patterns_w
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
           AND orcplp.flg_week IS NOT NULL;
    
        -- get number of plan patterns that have defined values for month and month day fields
        SELECT COUNT(1)
          INTO l_num_plan_patterns_m_md
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
           AND (orcplp.month IS NOT NULL OR orcplp.month_day IS NOT NULL);
    
        -- #5 "monthly recurrence pattern" order plan rule exception
        IF (l_order_recurr_plan.flg_recurr_pattern = 'M' AND l_order_recurr_plan.flg_repeat_by = 'W' AND
           (l_order_recurr_plan.repeat_every IS NULL OR l_num_plan_patterns_wd = 0 OR l_num_plan_patterns_w = 0 OR
           l_num_plan_patterns_m_md != 0))
        THEN
            g_error := '"monthly recurrence pattern" order plan rule exception';
            RAISE e_user_exception;
        END IF;
    
        -- get number of plan patterns that have defined values for month day field
        SELECT COUNT(1)
          INTO l_num_plan_patterns_md
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
           AND orcplp.month_day IS NOT NULL;
    
        -- get number of plan patterns that have defined values for week day, week and months fields
        SELECT COUNT(1)
          INTO l_num_plan_patterns_wd_w_m
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
           AND (orcplp.flg_week_day IS NOT NULL OR orcplp.flg_week IS NOT NULL AND orcplp.month IS NOT NULL);
    
        -- #6 "monthly recurrence pattern" order plan rule exception
        IF (l_order_recurr_plan.flg_recurr_pattern = 'M' AND l_order_recurr_plan.flg_repeat_by = 'M' AND
           (l_order_recurr_plan.repeat_every IS NULL OR l_num_plan_patterns_md = 0 OR l_num_plan_patterns_wd_w_m != 0))
        THEN
            g_error := '"monthly recurrence pattern" order plan rule exception';
            RAISE e_user_exception;
        END IF;
    
        -- get number of plan patterns that have defined values for month field
        SELECT COUNT(1)
          INTO l_num_plan_patterns_m
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
           AND orcplp.month IS NOT NULL;
    
        -- #7 "yearly recurrence pattern" order plan rule exception
        IF (l_order_recurr_plan.flg_recurr_pattern = 'Y' AND l_order_recurr_plan.flg_repeat_by = 'W' AND
           (l_order_recurr_plan.repeat_every IS NULL OR l_num_plan_patterns_wd = 0 OR l_num_plan_patterns_w = 0 OR
           l_num_plan_patterns_m = 0 OR l_num_plan_patterns_md != 0))
        THEN
            g_error := '"yearly recurrence pattern" order plan rule exception';
            RAISE e_user_exception;
        END IF;
    
        -- get number of plan patterns that have defined values for week day and week fields
        SELECT COUNT(1)
          INTO l_num_plan_patterns_wd_w
          FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
           AND (orcplp.flg_week_day IS NOT NULL OR orcplp.flg_week IS NOT NULL);
    
        -- #8 "yearly recurrence pattern" order plan rule exception
        IF (l_order_recurr_plan.flg_recurr_pattern = 'Y' AND l_order_recurr_plan.flg_repeat_by = 'M' AND
           (l_order_recurr_plan.repeat_every IS NULL OR l_num_plan_patterns_md = 0 OR l_num_plan_patterns_m = 0 OR
           l_num_plan_patterns_wd_w != 0))
        THEN
            g_error := '"yearly recurrence pattern" order plan rule exception';
            RAISE e_user_exception;
        END IF;
    
        RETURN TRUE;
    END check_orcpl_integrity_constr;

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
    ) RETURN VARCHAR2 IS
        l_order_recurr_option_desc VARCHAR2(1000 CHAR);
    BEGIN
    
        g_error := 'get order recurrence option description';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT pk_translation.get_translation(i_lang, orco.code_order_recurr_option) AS orco_desc
          INTO l_order_recurr_option_desc
          FROM order_recurr_option orco
         WHERE orco.id_order_recurr_option = i_order_recurr_option;
    
        RETURN l_order_recurr_option_desc;
    
    END get_order_recurr_option_desc;

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
    ) RETURN VARCHAR2 IS
        l_sysdate                TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_order_recurr_plan_desc VARCHAR2(1000 CHAR);
        rec_orcpl                order_recurr_plan%ROWTYPE;
        l_exec_times_desc        table_varchar;
        -- cursor to get order recurrence plan data
        CURSOR c_order_plan IS
            SELECT *
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan;
        -- cursor to get execution times
        CURSOR c_order_exec_times IS
            SELECT nvl2(exec_time_option, get_order_recurr_option_desc(i_lang, i_prof, exec_time_option) || ' (', NULL) ||
                   nvl2(exec_time_option,
                        get_exec_time_desc(i_lang, i_prof, exec_time_aux) || ')',
                        get_exec_time_desc(i_lang, i_prof, exec_time_aux))
              FROM (SELECT orcplt.id_order_recurr_option_parent AS exec_time_parent_option,
                           orcplt.id_order_recurr_option_child AS exec_time_option,
                           add_offset_to_tstz(orcplt.exec_time_offset,
                                              get_timestamp_day_tstz(i_lang, i_prof, l_sysdate) + orcplt.exec_time,
                                              orcplt.id_unit_meas_exec_time_offset) AS exec_time_aux,
                           orcplt.exec_time_offset AS exec_time_offset,
                           orcplt.id_unit_meas_exec_time_offset AS unit_meas_exec_time_offset
                      FROM order_recurr_plan_time orcplt
                     WHERE orcplt.id_order_recurr_plan = i_order_recurr_plan)
             ORDER BY encode_exec_time(i_lang, i_prof, exec_time_aux);
    BEGIN
        -- get order recurrence plan
        OPEN c_order_plan;
        FETCH c_order_plan
            INTO rec_orcpl;
        CLOSE c_order_plan;
        -- if user selected a predefined option, then show option description
        IF rec_orcpl.id_order_recurr_option != g_order_recurr_option_other
        THEN
            -- get option description
            l_order_recurr_plan_desc := get_order_recurr_option_desc(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_order_recurr_option => rec_orcpl.id_order_recurr_option);
        ELSE
            -- build other frequency description based in regular intervals
            IF rec_orcpl.regular_interval IS NOT NULL
            THEN
                l_order_recurr_plan_desc := to_char(rec_orcpl.regular_interval) || '/' ||
                                            to_char(rec_orcpl.regular_interval) || ' ' ||
                                            pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                         i_prof,
                                                                                         rec_orcpl.id_unit_meas_regular_interval);
                -- build other frequency description based in daily executions
            ELSIF rec_orcpl.daily_executions IS NOT NULL
            THEN
                l_order_recurr_plan_desc := to_char(rec_orcpl.daily_executions) || ' ' ||
                                            CASE rec_orcpl.daily_executions
                                                WHEN 1 THEN
                                                 pk_message.get_message(i_lang, 'ORDER_RECURRENCE_M002')
                                                ELSE
                                                 pk_message.get_message(i_lang, 'ORDER_RECURRENCE_M003')
                                            END;
                -- get execution times cursor
                OPEN c_order_exec_times;
                FETCH c_order_exec_times BULK COLLECT
                    INTO l_exec_times_desc;
                CLOSE c_order_exec_times;
                -- add to description available exec times
                IF l_exec_times_desc.count > 0
                THEN
                    -- add each exec time to the description
                    l_order_recurr_plan_desc := l_order_recurr_plan_desc || ' (' ||
                                                pk_utils.concat_table(l_exec_times_desc, ' - ') || ')';
                END IF;
            ELSE
                l_order_recurr_plan_desc := NULL;
            END IF;
        END IF;
        -- if we have a defined recurrence pattern defined in other frequencies
        IF rec_orcpl.id_order_recurr_option = g_order_recurr_option_other
           AND rec_orcpl.flg_recurr_pattern != g_flg_recurr_pattern_none
        THEN
            l_order_recurr_plan_desc := l_order_recurr_plan_desc || '; ' ||
                                        pk_message.get_message(i_lang, 'ORDER_RECURRENCE_T010') || ' ' ||
                                        rec_orcpl.repeat_every || ' ' ||
                                        pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                     i_prof,
                                                                                     get_unit_meas_repeat_interval(rec_orcpl.flg_recurr_pattern));
        END IF;
        -- TODO: process parent/child description and group child exec times when they share the same parent
        RETURN l_order_recurr_plan_desc;
    END get_order_recurr_pfreq_desc;

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
        l_order_plan_desc VARCHAR2(1000 CHAR);
        rec_orcpl         order_recurr_plan%ROWTYPE;
        l_occur_num       NUMBER;
        -- cursor to get order recurrence plan data
        CURSOR c_order_plan IS
            SELECT *
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan;
        CURSOR c_order_plan_occur IS
            SELECT COUNT(*)
              FROM icnp_interv_plan iip
             WHERE iip.id_icnp_epis_interv IN
                   (SELECT DISTINCT iip_o.id_icnp_epis_interv
                      FROM icnp_interv_plan iip_o
                     WHERE iip_o.id_order_recurr_plan = i_order_recurr_plan)
               AND iip.flg_status NOT IN (pk_icnp_constant.g_interv_plan_status_freq_alt); --To consider canceled tasks?
    
    BEGIN
        -- get order recurrence plan
        OPEN c_order_plan;
        FETCH c_order_plan
            INTO rec_orcpl;
        CLOSE c_order_plan;
    
        OPEN c_order_plan_occur;
        FETCH c_order_plan_occur
            INTO l_occur_num;
        CLOSE c_order_plan_occur;
    
        -- get order recurrence plan frequency description
        l_order_plan_desc := pk_order_recurrence_core.get_order_recurr_pfreq_desc(i_lang              => i_lang,
                                                                                  i_prof              => i_prof,
                                                                                  i_order_recurr_plan => i_order_recurr_plan);
    
        -- if user selected other that the "once" predefined option, then show order end plan information
        IF rec_orcpl.id_order_recurr_option != g_order_recurr_option_once
        THEN
            -- process order plan end
            CASE
            -- no end date
                WHEN rec_orcpl.flg_end_by = g_flg_end_by_no_end THEN
                    l_order_plan_desc := l_order_plan_desc || '; ' ||
                                         pk_sysdomain.get_domain('ORDER_RECURR.FLG_END_BY', g_flg_end_by_no_end, i_lang);
                    -- end date
                WHEN rec_orcpl.flg_end_by = g_flg_end_by_date
                     AND i_flg_show_date = pk_alert_constant.g_yes THEN
                    l_order_plan_desc := l_order_plan_desc || '; ' ||
                                         pk_message.get_message(i_lang, 'ORDER_RECURRENCE_T018') || ' ' ||
                                         pk_date_utils.date_char_tsz(i_lang,
                                                                     rec_orcpl.end_date,
                                                                     i_prof.institution,
                                                                     i_prof.software);
                    -- end by occurrences
                WHEN rec_orcpl.flg_end_by = g_flg_end_by_occurrences THEN
                    l_order_plan_desc := l_order_plan_desc || '; ' || pk_message.get_message(i_lang, 'ORDER_RECURRENCE_T018') || ' ' ||
                                         to_char(CASE
                                                     WHEN l_occur_num > 0 THEN
                                                      l_occur_num
                                                     ELSE
                                                      rec_orcpl.occurrences
                                                 END) || ' ' || pk_message.get_message(i_lang, 'ORDER_RECURRENCE_M001');
                    -- end by duration
                WHEN rec_orcpl.flg_end_by = g_flg_end_by_duration THEN
                    l_order_plan_desc := l_order_plan_desc || '; ' ||
                                         pk_message.get_message(i_lang, 'ORDER_RECURRENCE_T018') || ' ' ||
                                         to_char(rec_orcpl.duration) || ' ' ||
                                         pk_unit_measure.get_unit_measure_description(i_lang,
                                                                                      i_prof,
                                                                                      rec_orcpl.id_unit_meas_duration);
                ELSE
                    NULL;
            END CASE;
        END IF;
        RETURN l_order_plan_desc;
    END get_order_recurr_plan_desc;

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
    ) RETURN BOOLEAN IS
    
        l_avail_predef_time_options t_tbl_orcomsi;
    
    BEGIN
    
        g_error := 'call get_avail_order_recurr_options function';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT get_avail_order_recurr_options(i_lang                 => i_lang,
                                              i_prof                 => i_prof,
                                              i_order_recurr_area    => i_order_recurr_area,
                                              i_flg_selection_domain => g_flg_select_dom_predef_sch,
                                              o_order_recurr_option  => l_avail_predef_time_options,
                                              o_error                => o_error)
        THEN
            g_error := 'error found while calling get_avail_order_recurr_options function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'get o_predef_time_schedules cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_predef_time_schedules FOR
            SELECT /*+OPT_ESTIMATE (table avail_orco rows=1)*/
             orco.id_order_recurr_option AS id_predef_time_schedule,
             orco.internal_name,
             pk_translation.get_translation(i_lang, orco.code_order_recurr_option) AS predef_time_schedule_desc,
             avail_orco.rank,
             avail_orco.flg_default
              FROM order_recurr_option orco
             INNER JOIN TABLE(CAST(l_avail_predef_time_options AS t_tbl_orcomsi)) avail_orco
                ON (orco.id_order_recurr_option = avail_orco.id_order_recurr_option)
              LEFT OUTER JOIN order_recurr orc
                ON (orco.id_order_recurr_option = orc.id_order_recurr_option)
             WHERE orco.flg_selection_domain IN (g_flg_select_dom_both, g_flg_select_dom_predef_sch)
             ORDER BY avail_orco.rank, upper(predef_time_schedule_desc);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PREDEFINED_TIME_SCHEDULES',
                                              o_error);
        
            pk_types.open_my_cursor(o_predef_time_schedules);
            RETURN FALSE;
    END get_predefined_time_schedules;

    FUNCTION get_predefined_time_schedules
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_area IN order_recurr_area.internal_name%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_avail_predef_time_options t_tbl_orcomsi;
    
        l_ret t_tbl_core_domain;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'call get_avail_order_recurr_options function';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT get_avail_order_recurr_options(i_lang                 => i_lang,
                                              i_prof                 => i_prof,
                                              i_order_recurr_area    => i_order_recurr_area,
                                              i_flg_selection_domain => g_flg_select_dom_predef_sch,
                                              o_order_recurr_option  => l_avail_predef_time_options,
                                              o_error                => l_error)
        THEN
            g_error := 'error found while calling get_avail_order_recurr_options function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'get o_predef_time_schedules cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => t.predef_time_schedule_desc,
                                 domain_value  => t.id_predef_time_schedule,
                                 order_rank    => t.rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT /*+OPT_ESTIMATE (table avail_orco rows=1)*/
                 orco.id_order_recurr_option AS id_predef_time_schedule,
                 orco.internal_name,
                 pk_translation.get_translation(i_lang, orco.code_order_recurr_option) AS predef_time_schedule_desc,
                 avail_orco.rank
                  FROM order_recurr_option orco
                 INNER JOIN TABLE(CAST(l_avail_predef_time_options AS t_tbl_orcomsi)) avail_orco
                    ON (orco.id_order_recurr_option = avail_orco.id_order_recurr_option)
                  LEFT OUTER JOIN order_recurr orc
                    ON (orco.id_order_recurr_option = orc.id_order_recurr_option)
                 WHERE orco.flg_selection_domain IN (g_flg_select_dom_both, g_flg_select_dom_predef_sch)
                 ORDER BY avail_orco.rank, upper(predef_time_schedule_desc)) t;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PREDEFINED_TIME_SCHEDULES',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_predefined_time_schedules;

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
    ) RETURN BOOLEAN IS
    
        l_avail_order_recurr_options t_tbl_orcomsi;
    
    BEGIN
    
        g_error := 'call get_avail_order_recurr_options function';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT get_avail_order_recurr_options(i_lang                 => i_lang,
                                              i_prof                 => i_prof,
                                              i_order_recurr_area    => i_order_recurr_area,
                                              i_flg_selection_domain => g_flg_select_dom_order_recurr,
                                              o_order_recurr_option  => l_avail_order_recurr_options,
                                              o_error                => o_error)
        THEN
            g_error := 'error found while calling get_avail_order_recurr_options function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'get o_predef_time_sch cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_order_recurr_options FOR
            SELECT /*+OPT_ESTIMATE (table avail_orco rows=1)*/
             orco.id_order_recurr_option,
             orco.internal_name,
             pk_translation.get_translation(i_lang, orco.code_order_recurr_option) AS order_recurr_option_desc,
             avail_orco.rank,
             avail_orco.flg_default
              FROM order_recurr_option orco
             INNER JOIN TABLE(CAST(l_avail_order_recurr_options AS t_tbl_orcomsi)) avail_orco
                ON (orco.id_order_recurr_option = avail_orco.id_order_recurr_option)
              LEFT OUTER JOIN order_recurr orc
                ON (orco.id_order_recurr_option = orc.id_order_recurr_option)
             WHERE orco.flg_selection_domain IN (g_flg_select_dom_both, g_flg_select_dom_order_recurr)
             ORDER BY avail_orco.rank, upper(order_recurr_option_desc);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MOST_FREQUENT_RECURRENCES',
                                              o_error);
        
            pk_types.open_my_cursor(o_order_recurr_options);
            RETURN FALSE;
    END get_most_frequent_recurrences;

    FUNCTION get_most_frequent_recurrences
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_area IN order_recurr_area.internal_name%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_avail_order_recurr_options t_tbl_orcomsi;
    
        l_ret t_tbl_core_domain;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'call get_avail_order_recurr_options function';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT get_avail_order_recurr_options(i_lang                 => i_lang,
                                              i_prof                 => i_prof,
                                              i_order_recurr_area    => i_order_recurr_area,
                                              i_flg_selection_domain => g_flg_select_dom_order_recurr,
                                              o_order_recurr_option  => l_avail_order_recurr_options,
                                              o_error                => l_error)
        THEN
            g_error := 'error found while calling get_avail_order_recurr_options function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'get l_ret cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => t.order_recurr_option_desc,
                                 domain_value  => t.id_order_recurr_option,
                                 order_rank    => t.rank,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT /*+OPT_ESTIMATE (table avail_orco rows=1)*/
                 orco.id_order_recurr_option,
                 orco.internal_name,
                 pk_translation.get_translation(i_lang, orco.code_order_recurr_option) AS order_recurr_option_desc,
                 avail_orco.rank
                  FROM order_recurr_option orco
                 INNER JOIN TABLE(CAST(l_avail_order_recurr_options AS t_tbl_orcomsi)) avail_orco
                    ON (orco.id_order_recurr_option = avail_orco.id_order_recurr_option)
                  LEFT OUTER JOIN order_recurr orc
                    ON (orco.id_order_recurr_option = orc.id_order_recurr_option)
                 WHERE orco.flg_selection_domain IN (g_flg_select_dom_both, g_flg_select_dom_order_recurr)
                 ORDER BY avail_orco.rank, upper(order_recurr_option_desc)) t;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MOST_FREQUENT_RECURRENCES',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_most_frequent_recurrences;

    FUNCTION get_order_recurr_plan_end
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_domain      IN VARCHAR2,
        i_flg_context IN VARCHAR2,
        o_domains     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_domains FOR
            SELECT s.val, s.desc_val, s.rank, s.img_name
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'ORDER_RECURR_PLAN.FLG_END_BY', NULL)) s
             WHERE (i_flg_context = pk_order_recurrence_core.g_context_patient OR
                   (s.val NOT IN
                   (pk_order_recurrence_core.g_flg_end_by_date, pk_order_recurrence_core.g_flg_end_by_duration) AND
                   i_flg_context = pk_order_recurrence_core.g_context_settings))
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_RECURR_PLAN_END',
                                              o_error);
            pk_types.open_my_cursor(o_domains);
            RETURN FALSE;
    END get_order_recurr_plan_end;

    FUNCTION get_order_recurr_plan_end
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_domain      IN VARCHAR2,
        i_flg_context IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_ret t_tbl_core_domain;
    
        l_error t_error_out;
    
    BEGIN
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => t.desc_val,
                                 domain_value  => t.val,
                                 order_rank    => t.rank,
                                 img_name      => nvl2(t.img_name, 'icon-', NULL) || t.img_name)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT s.val, s.desc_val, s.rank, s.img_name
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                      i_prof,
                                                                      'ORDER_RECURR_PLAN.FLG_END_BY',
                                                                      NULL)) s
                 WHERE (i_flg_context = pk_order_recurrence_core.g_context_patient OR
                       (s.val NOT IN
                       (pk_order_recurrence_core.g_flg_end_by_date, pk_order_recurrence_core.g_flg_end_by_duration) AND
                       i_flg_context = pk_order_recurrence_core.g_context_settings))
                 ORDER BY rank, desc_val) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_RECURR_PLAN_END',
                                              l_error);
    END get_order_recurr_plan_end;

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
    ) RETURN BOOLEAN IS
    
        l_order_recurr_option   order_recurr_option.id_order_recurr_option%TYPE;
        l_new_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE;
    BEGIN
        -- if order recurrence option input parameter is null, get default order recurrence option
        IF i_order_recurr_option IS NULL
        THEN
        
            g_error := 'get default order recurrence option';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            IF NOT get_def_order_recurr_option(i_lang                   => i_lang,
                                               i_prof                   => i_prof,
                                               i_order_recurr_area      => i_order_recurr_area,
                                               o_id_order_recurr_option => l_order_recurr_option,
                                               o_error                  => o_error)
            THEN
                g_error := 'error while calling get_def_order_recurr_option function';
                RAISE e_user_exception;
            END IF;
        ELSE
            l_order_recurr_option := i_order_recurr_option;
        END IF;
    
        g_error := 'create order recurrence plan';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get new order recurrence plan id
        SELECT seq_order_recurr_plan.nextval
          INTO l_new_order_recurr_plan
          FROM dual;
    
        -- create order recurrence plan
        IF NOT set_order_recurr_option(i_lang                         => i_lang,
                                       i_prof                         => i_prof,
                                       i_order_recurr_plan            => l_new_order_recurr_plan,
                                       i_order_recurr_option          => l_order_recurr_option,
                                       i_order_recurr_area            => i_order_recurr_area,
                                       i_flg_new_order_recurr_plan    => pk_alert_constant.g_yes,
                                       i_flg_include_start_dt_in_plan => i_flg_include_start_dt_in_plan,
                                       i_flg_status                   => i_flg_status,
                                       o_order_recurr_desc            => o_order_recurr_desc,
                                       o_start_date                   => o_start_date,
                                       o_occurrences                  => o_occurrences,
                                       o_duration                     => o_duration,
                                       o_unit_meas_duration           => o_unit_meas_duration,
                                       o_end_date                     => o_end_date,
                                       o_flg_end_by_editable          => o_flg_end_by_editable,
                                       o_error                        => o_error)
        THEN
            g_error := 'error while calling set_order_recurr_option function';
            RAISE e_user_exception;
        END IF;
    
        -- set output parameter with the order recurrence plan id
        o_order_recurr_plan := l_new_order_recurr_plan;
    
        -- set output parameter with default order recurrence option id
        o_order_recurr_option := l_order_recurr_option;
    
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
    * duplicate/copy an existing order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan_from existing order recurrence plan to copy from
    * @param       i_flg_dup_control_table  flag that indicates if order_recurr_control record
    *                                       should be duplicated or not
    * @param       i_flg_force_temp_plan    duplicated plan can be forced as temporary or not
    * @param       o_order_recurr_plan_to   new order recurrence plan id for created copy
    * @param       o_error                  error structure for exception handling
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @value       i_flg_force_temp_plan    {*} 'Y' duplicated plan shall be temporary
    *                                       {*} 'N' duplicate plan assigning original status value
    *
    * @value       i_flg_dup_control_table  {*} 'Y' order_recurr_control table record will be duplicated
    *                                       {*} 'N' no duplication of order_recurr_control table record
    *
    * @author                               Carlos Loureiro
    * @since                                05-DEC-2011
    ********************************************************************************************/
    FUNCTION duplicate_order_recurr_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_recurr_plan_from IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_dup_control_table  IN VARCHAR2,
        i_flg_force_temp_plan    IN VARCHAR2,
        o_order_recurr_plan_to   OUT order_recurr_plan.id_order_recurr_plan%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_new_order_recurr_plan order_recurr_plan.id_order_recurr_plan%TYPE;
    BEGIN
        -- get new order recurrence plan id
        SELECT seq_order_recurr_plan.nextval
          INTO l_new_order_recurr_plan
          FROM dual;
    
        -- copy order_recurr_plan record
        g_error := 'copy from [' || i_order_recurr_plan_from || '] to [' || l_new_order_recurr_plan ||
                   '] in order_recurr_plan table';
        pk_alertlog.log_debug(g_error, g_package_name);
        INSERT INTO order_recurr_plan
            (id_order_recurr_plan,
             id_order_recurr_option,
             regular_interval,
             id_unit_meas_regular_interval,
             daily_executions,
             flg_recurr_pattern,
             repeat_every,
             flg_repeat_by,
             start_date,
             flg_end_by,
             occurrences,
             duration,
             id_unit_meas_duration,
             end_date,
             flg_status,
             id_institution,
             id_professional,
             id_order_recurr_area)
            SELECT l_new_order_recurr_plan,
                   id_order_recurr_option,
                   regular_interval,
                   id_unit_meas_regular_interval,
                   daily_executions,
                   flg_recurr_pattern,
                   repeat_every,
                   flg_repeat_by,
                   start_date,
                   flg_end_by,
                   occurrences,
                   duration,
                   id_unit_meas_duration,
                   end_date,
                   CASE i_flg_force_temp_plan
                       WHEN pk_alert_constant.g_yes THEN
                        g_plan_status_temp -- copied plan is started in temporary status
                       ELSE
                        flg_status -- assume original value
                   END,
                   id_institution,
                   id_professional,
                   id_order_recurr_area
              FROM order_recurr_plan
             WHERE id_order_recurr_plan = i_order_recurr_plan_from;
    
        -- copy order_recurr_plan_pattern record
        g_error := 'copy from [' || i_order_recurr_plan_from || '] to [' || l_new_order_recurr_plan ||
                   '] in order_recurr_pla_pattern table';
        pk_alertlog.log_debug(g_error, g_package_name);
        INSERT INTO order_recurr_plan_pattern
            (id_order_recurr_plan_pattern, id_order_recurr_plan, flg_week_day, flg_week, month_day, MONTH)
            SELECT seq_order_recurr_plan_pattern.nextval,
                   l_new_order_recurr_plan,
                   flg_week_day,
                   flg_week,
                   month_day,
                   MONTH
              FROM order_recurr_plan_pattern
             WHERE id_order_recurr_plan = i_order_recurr_plan_from;
    
        -- copy order_recurr_plan_time record
        g_error := 'copy from [' || i_order_recurr_plan_from || '] to [' || l_new_order_recurr_plan ||
                   '] in order_recurr_plan_time table';
        pk_alertlog.log_debug(g_error, g_package_name);
        INSERT INTO order_recurr_plan_time
            (id_order_recurr_plan_time,
             id_order_recurr_plan,
             id_order_recurr_option_parent,
             id_order_recurr_option_child,
             exec_time,
             exec_time_offset,
             id_unit_meas_exec_time_offset)
            SELECT seq_order_recurr_plan_time.nextval,
                   l_new_order_recurr_plan,
                   id_order_recurr_option_parent,
                   id_order_recurr_option_child,
                   exec_time,
                   exec_time_offset,
                   id_unit_meas_exec_time_offset
              FROM order_recurr_plan_time a
             WHERE id_order_recurr_plan = i_order_recurr_plan_from;
    
        -- check if order_recurr_control table record should be also duplicated
        IF i_flg_dup_control_table = pk_alert_constant.g_yes
        THEN
            -- copy order_recurr_control record
            g_error := 'copy from [' || i_order_recurr_plan_from || '] to [' || l_new_order_recurr_plan ||
                       '] in order_recurr_control table';
            pk_alertlog.log_debug(g_error, g_package_name);
            INSERT INTO order_recurr_control
                (id_order_recurr_plan,
                 dt_last_processed,
                 flg_status,
                 id_order_recurr_area,
                 last_exec_order,
                 dt_last_exec)
                SELECT l_new_order_recurr_plan,
                       orcc.dt_last_processed,
                       orcc.flg_status,
                       orcc.id_order_recurr_area,
                       orcc.last_exec_order,
                       orcc.dt_last_exec
                  FROM order_recurr_control orcc
                 WHERE orcc.id_order_recurr_plan = i_order_recurr_plan_from;
        END IF;
    
        -- assign newly created plan
        o_order_recurr_plan_to := l_new_order_recurr_plan;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DUPLICATE_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END duplicate_order_recurr_plan;

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
    ) RETURN BOOLEAN IS
    BEGIN
        -- duplicate plan
        g_error := 'duplicate order recurrence plan';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT duplicate_order_recurr_plan(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_order_recurr_plan_from => i_order_recurr_plan_from,
                                           i_flg_dup_control_table  => pk_alert_constant.g_yes,
                                           i_flg_force_temp_plan    => i_flg_force_temp_plan,
                                           o_order_recurr_plan_to   => o_order_recurr_plan,
                                           o_error                  => o_error)
        THEN
            g_error := 'error found while calling duplicate_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- get order recurrence instructions
        g_error := 'get order recurrence instructions';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT get_order_recurr_instructions(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_order_plan          => o_order_recurr_plan,
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
            g_error := 'error while calling get_order_recurr_instructions function';
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
                                              'COPY_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END copy_order_recurr_plan;

    FUNCTION copy_order_recurr_plan
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_recurr_plan_from IN order_recurr_plan.id_order_recurr_plan%TYPE,
        i_flg_force_temp_plan    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_first_loop         IN VARCHAR2,
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
    ) RETURN BOOLEAN IS
    BEGIN
        -- duplicate plan
        g_error := 'duplicate order recurrence plan';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT duplicate_order_recurr_plan(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_order_recurr_plan_from => i_order_recurr_plan_from,
                                           i_flg_dup_control_table  => pk_alert_constant.g_yes,
                                           i_flg_force_temp_plan    => i_flg_force_temp_plan,
                                           o_order_recurr_plan_to   => o_order_recurr_plan,
                                           o_error                  => o_error)
        THEN
            g_error := 'error found while calling duplicate_order_recurr_plan function';
            RAISE e_user_exception;
        END IF;
    
        -- get order recurrence instructions
        g_error := 'get order recurrence instructions';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF i_flg_first_loop = pk_alert_constant.g_yes
        THEN
            IF NOT get_order_recurr_instructions(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_order_plan          => o_order_recurr_plan,
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
                g_error := 'error while calling get_order_recurr_instructions function';
                RAISE e_user_exception;
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
                                              'COPY_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END copy_order_recurr_plan;

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
    ) RETURN BOOLEAN IS
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_start_date          TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date            TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
    
    BEGIN
        -- if i_order_recurr_plan_from is null, then create a new plan and assume "once" option
        IF i_order_recurr_plan_from IS NULL
        THEN
            -- call pk_order_recurrence_core.create_order_recurr_plan function
            IF NOT create_order_recurr_plan(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_order_recurr_area   => i_order_recurr_area,
                                            o_order_recurr_desc   => o_order_recurr_desc,
                                            o_order_recurr_option => l_order_recurr_option,
                                            o_start_date          => o_start_date,
                                            o_occurrences         => o_occurrences,
                                            o_duration            => o_duration,
                                            o_unit_meas_duration  => o_unit_meas_duration,
                                            o_end_date            => o_end_date,
                                            o_flg_end_by_editable => o_flg_end_by_editable,
                                            o_order_recurr_plan   => o_order_recurr_plan,
                                            o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        
            -- check if default option is "once" for the created order recurrence plan. if not, set "once" option
            IF l_order_recurr_option != g_order_recurr_option_once
            THEN
                -- set a "once" order recurrence option for the created order recurrence plan
                IF NOT set_order_recurr_option(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_order_recurr_plan   => o_order_recurr_plan,
                                               i_order_recurr_option => g_order_recurr_option_once,
                                               o_order_recurr_desc   => o_order_recurr_desc,
                                               o_start_date          => o_start_date, -- l_start_date contains the 1st exec timestamp
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
            ELSE
                o_order_recurr_option := g_order_recurr_option_once;
            END IF;
        
        ELSE
            -- copy previous plan
        
            -- call pk_order_recurrence_core.copy_order_recurr_plan function
            IF NOT copy_order_recurr_plan(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_order_recurr_plan_from => i_order_recurr_plan_from,
                                          i_flg_force_temp_plan    => i_flg_force_temp_plan,
                                          o_order_recurr_desc      => o_order_recurr_desc,
                                          o_order_recurr_option    => o_order_recurr_option,
                                          o_start_date             => l_start_date,
                                          o_occurrences            => o_occurrences,
                                          o_duration               => o_duration,
                                          o_unit_meas_duration     => o_unit_meas_duration,
                                          o_end_date               => l_end_date,
                                          o_flg_end_by_editable    => o_flg_end_by_editable,
                                          o_order_recurr_plan      => o_order_recurr_plan,
                                          o_error                  => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        
            -- set new order recurrence instructions for a given order recurrence plan
            IF NOT set_order_recurr_instructions(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_order_recurr_plan   => o_order_recurr_plan,
                                                 i_start_date          => l_sysdate,
                                                 i_occurrences         => o_occurrences,
                                                 i_duration            => o_duration,
                                                 i_unit_meas_duration  => o_unit_meas_duration,
                                                 i_end_date            => NULL,
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
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                RAISE e_user_exception;
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
                                              'COPY_FROM_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END copy_from_order_recurr_plan;

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
    ) RETURN BOOLEAN IS
        l_start_date          TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date            TIMESTAMP WITH LOCAL TIME ZONE;
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
    
    BEGIN
        -- if i_order_recurr_plan_from is null, then create a new plan and assume desired plan option (if not defined, assume "once")
        IF i_order_recurr_plan_from IS NULL
        THEN
            -- call pk_order_recurrence_core.create_order_recurr_plan function
            IF NOT create_order_recurr_plan(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_order_recurr_area   => i_order_recurr_area,
                                            o_order_recurr_desc   => o_order_recurr_desc,
                                            o_order_recurr_option => l_order_recurr_option,
                                            o_start_date          => o_start_date,
                                            o_occurrences         => o_occurrences,
                                            o_duration            => o_duration,
                                            o_unit_meas_duration  => o_unit_meas_duration,
                                            o_end_date            => o_end_date,
                                            o_flg_end_by_editable => o_flg_end_by_editable,
                                            o_order_recurr_plan   => o_order_recurr_plan,
                                            o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        ELSE
            -- copy previous plan
            -- call pk_order_recurrence_core.copy_order_recurr_plan function
            IF NOT copy_order_recurr_plan(i_lang                   => i_lang,
                                          i_prof                   => i_prof,
                                          i_order_recurr_plan_from => i_order_recurr_plan_from,
                                          o_order_recurr_desc      => o_order_recurr_desc,
                                          o_order_recurr_option    => l_order_recurr_option,
                                          o_start_date             => l_start_date,
                                          o_occurrences            => o_occurrences,
                                          o_duration               => o_duration,
                                          o_unit_meas_duration     => o_unit_meas_duration,
                                          o_end_date               => l_end_date,
                                          o_flg_end_by_editable    => o_flg_end_by_editable,
                                          o_order_recurr_plan      => o_order_recurr_plan,
                                          o_error                  => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        END IF;
    
        -- if an option (not the "other frequency" one) was selected (if no option was defined, assume "once" option)
        IF nvl(i_order_recurr_option, g_order_recurr_option_once) != g_order_recurr_option_other
        THEN
            -- if no option was defined, assume "once" option
            IF nvl(i_order_recurr_option, g_order_recurr_option_once) != l_order_recurr_option
            THEN
                -- set order recurrence option for the created order recurrence plan (if not the desired one)
                IF NOT
                    set_order_recurr_option(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_order_recurr_plan   => o_order_recurr_plan,
                                            i_order_recurr_option => nvl(i_order_recurr_option, g_order_recurr_option_once),
                                            o_order_recurr_desc   => o_order_recurr_desc,
                                            o_start_date          => l_start_date,
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
            
            END IF;
        END IF;
    
        -- set new order recurrence instructions for a given order recurrence plan (adjust start date)
        IF NOT set_order_recurr_instructions(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_order_recurr_plan   => o_order_recurr_plan,
                                             i_start_date          => i_start_date,
                                             i_occurrences         => i_occurrences,
                                             i_duration            => o_duration,
                                             i_unit_meas_duration  => o_unit_meas_duration,
                                             i_end_date            => i_end_date,
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
            g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
        -- if selected option is "other frequencies" (then force "other frequencies" pop-up by overriding plan option)
        IF i_order_recurr_option = g_order_recurr_option_other
        THEN
            o_order_recurr_option := g_order_recurr_option_other;
        
            IF o_start_date IS NULL
            THEN
                o_start_date := current_timestamp;
            END IF;
        END IF;
    
        --ALERT-333539 When the user select another option, then respect the new start date. 
        --In the upper case, the code respect the start date entered (eg: change next_intervention
        IF l_order_recurr_option != i_order_recurr_option
        THEN
            o_start_date := l_start_date;
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
                                              'EDIT_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END edit_order_recurr_plan;

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
    * @param       i_flg_status                       flag that indicates order recurrence plan status (only used when i_flg_new_order_recurr_plan=Y)
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
    ) RETURN BOOLEAN IS
    
        -- cursor used to get order recurrence plan data
        CURSOR c_order_recurr_plan
        (
            in_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE,
            in_order_recurr_option IN order_recurr.id_order_recurr_option%TYPE
        ) IS
            SELECT in_order_recurr_plan              AS id_order_recurr_plan,
                   in_order_recurr_option            AS id_order_recurr_option,
                   orc.regular_interval,
                   orc.id_unit_meas_regular_interval,
                   orc.daily_executions,
                   orc.flg_recurr_pattern,
                   orc.repeat_every,
                   orc.flg_repeat_by,
                   orc.flg_end_by,
                   orc.occurrences,
                   orc.duration,
                   orc.id_unit_meas_duration
              FROM order_recurr orc
             WHERE orc.id_order_recurr_option = in_order_recurr_option;
    
        -- cursor used to get order recurrence plan pattern data
        CURSOR c_order_recurr_plan_pattern
        (
            in_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE,
            in_order_recurr_option IN order_recurr.id_order_recurr_option%TYPE
        ) IS
            SELECT seq_order_recurr_plan_pattern.nextval AS id_order_recurr_plan_pattern,
                   in_order_recurr_plan                  AS id_order_recurr_plan,
                   orcp.flg_week_day,
                   orcp.flg_week,
                   orcp.month_day,
                   orcp.month
              FROM order_recurr_pattern orcp
             INNER JOIN order_recurr orc
                ON orcp.id_order_recurr = orc.id_order_recurr
             WHERE orc.id_order_recurr_option = in_order_recurr_option;
    
        -- cursor used to get order recurrence plan time data
        CURSOR c_order_recurr_plan_time
        (
            in_order_recurr_time IN t_tbl_orcotmsi,
            in_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
        ) IS
            SELECT seq_order_recurr_plan_time.nextval     AS id_order_recurr_plan_time,
                   in_order_recurr_plan                   AS id_order_recurr_plan,
                   NULL                                   AS id_order_recurr_option_parent,
                   orcotmsi.id_order_recurr_option        AS id_order_recurr_option_child,
                   orcotmsi.exec_time,
                   orcotmsi.exec_time_offset,
                   orcotmsi.id_unit_meas_exec_time_offset
              FROM TABLE(CAST(in_order_recurr_time AS t_tbl_orcotmsi)) orcotmsi
             WHERE orcotmsi.exec_time IS NOT NULL;
    
        -- auxiliary local variables
        l_new_rec_order_recurr_plan c_order_recurr_plan%ROWTYPE;
        l_order_recurr_plan         order_recurr_plan%ROWTYPE;
    
        l_orcplp_counter PLS_INTEGER := 0;
        TYPE t_order_recurr_plan_pattern IS TABLE OF order_recurr_plan_pattern%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_order_recurr_plan_pattern t_order_recurr_plan_pattern;
    
        l_orcplt_counter PLS_INTEGER := 0;
        TYPE t_order_recurr_plan_time IS TABLE OF order_recurr_plan_time%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_order_recurr_plan_time t_order_recurr_plan_time;
    
        l_order_recurr_time t_tbl_orcotmsi;
    
        l_order_recurr_area order_recurr_area.id_order_recurr_area%TYPE;
    
        l_prev_start_date        order_recurr_plan.start_date%TYPE;
        l_new_start_date         order_recurr_plan.start_date%TYPE;
        l_new_occurrences        order_recurr_plan.occurrences%TYPE;
        l_new_duration           order_recurr_plan.duration%TYPE;
        l_new_unit_meas_duration order_recurr_plan.id_unit_meas_duration%TYPE;
        l_new_end_date           order_recurr_plan.end_date%TYPE;
    
        l_order_recurr_option order_recurr_option.id_order_recurr_option%TYPE;
        l_flg_status          order_recurr_plan.flg_status%TYPE;
    
        l_start_date order_recurr_plan.start_date%TYPE;
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        g_error := 'check if this is a new order recurrence plan';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- check if this is a new order recurrence plan or not
        IF i_flg_new_order_recurr_plan = pk_alert_constant.g_no
        THEN
        
            g_error := 'get order recurrence area of the previous plan';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- get order recurrence area of the previous plan
            BEGIN
                SELECT orcpl.id_order_recurr_area, orcpl.flg_status, orcpl.start_date
                  INTO l_order_recurr_area, l_flg_status, l_start_date
                  FROM order_recurr_plan orcpl
                 WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
                   AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined);
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'Order recurrence plan id does not exist or it is not in a temporary or predefined status';
                    RAISE e_user_exception;
            END;
        
            g_error := 'delete previous order recurrence plan data';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            IF NOT cancel_order_recurr_plan(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_order_recurr_plan => i_order_recurr_plan,
                                            i_flg_persist_plan  => pk_alert_constant.g_yes,
                                            o_error             => o_error)
            THEN
                g_error := 'error while calling cancel_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        
            IF l_start_date > l_sysdate
            THEN
                l_prev_start_date := l_sysdate;
            ELSE
                l_prev_start_date := l_start_date;
            END IF;
        
        ELSE
            -- if this is a new order recurrence plan, order recurrence area must be an input parameter
            IF i_flg_status IS NULL
               OR i_flg_status NOT IN (g_plan_status_temp, g_plan_status_predefined)
            THEN
                g_error := 'Order recurrence plan must be in temporary or predefined status';
                RAISE e_user_exception;
            ELSE
                l_flg_status := i_flg_status;
            END IF;
        
            g_error := 'get order recurrence area id';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- get order recurrence area id
            SELECT orca.id_order_recurr_area
              INTO l_order_recurr_area
              FROM order_recurr_area orca
             WHERE orca.internal_name = i_order_recurr_area;
        
            l_prev_start_date := trunc_timestamp_to_minutes(i_lang, i_prof, l_sysdate);
        
        END IF;
    
        g_error := 'prepare new record for order recurrence plan table';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- prepare new record for order recurrence plan table
        OPEN c_order_recurr_plan(i_order_recurr_plan, i_order_recurr_option);
        FETCH c_order_recurr_plan
            INTO l_new_rec_order_recurr_plan;
        CLOSE c_order_recurr_plan;
    
        l_order_recurr_plan.id_order_recurr_plan           := l_new_rec_order_recurr_plan.id_order_recurr_plan;
        l_order_recurr_plan.id_order_recurr_option         := l_new_rec_order_recurr_plan.id_order_recurr_option;
        l_order_recurr_plan.regular_interval               := l_new_rec_order_recurr_plan.regular_interval;
        l_order_recurr_plan.id_unit_meas_regular_interval  := l_new_rec_order_recurr_plan.id_unit_meas_regular_interval;
        l_order_recurr_plan.daily_executions               := l_new_rec_order_recurr_plan.daily_executions;
        l_order_recurr_plan.flg_recurr_pattern             := l_new_rec_order_recurr_plan.flg_recurr_pattern;
        l_order_recurr_plan.repeat_every                   := l_new_rec_order_recurr_plan.repeat_every;
        l_order_recurr_plan.flg_repeat_by                  := l_new_rec_order_recurr_plan.flg_repeat_by;
        l_order_recurr_plan.start_date                     := l_prev_start_date;
        l_order_recurr_plan.flg_end_by                     := l_new_rec_order_recurr_plan.flg_end_by;
        l_order_recurr_plan.occurrences                    := l_new_rec_order_recurr_plan.occurrences;
        l_order_recurr_plan.duration                       := l_new_rec_order_recurr_plan.duration;
        l_order_recurr_plan.id_unit_meas_duration          := l_new_rec_order_recurr_plan.id_unit_meas_duration;
        l_order_recurr_plan.end_date                       := NULL;
        l_order_recurr_plan.flg_status                     := l_flg_status;
        l_order_recurr_plan.id_institution                 := i_prof.institution;
        l_order_recurr_plan.id_professional                := i_prof.id;
        l_order_recurr_plan.id_order_recurr_area           := l_order_recurr_area;
        l_order_recurr_plan.flg_include_start_date_in_plan := i_flg_include_start_dt_in_plan;
    
        g_error := 'insert new order recurrence plan';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- insert/update new order recurrence plan
        MERGE INTO order_recurr_plan orp
        USING (SELECT l_order_recurr_plan.id_order_recurr_plan           AS id_order_recurr_plan,
                      l_order_recurr_plan.id_order_recurr_option         AS id_order_recurr_option,
                      l_order_recurr_plan.regular_interval               AS regular_interval,
                      l_order_recurr_plan.id_unit_meas_regular_interval  AS id_unit_meas_regular_interval,
                      l_order_recurr_plan.daily_executions               AS daily_executions,
                      l_order_recurr_plan.flg_recurr_pattern             AS flg_recurr_pattern,
                      l_order_recurr_plan.repeat_every                   AS repeat_every,
                      l_order_recurr_plan.flg_repeat_by                  AS flg_repeat_by,
                      l_order_recurr_plan.start_date                     AS start_date,
                      l_order_recurr_plan.flg_end_by                     AS flg_end_by,
                      l_order_recurr_plan.occurrences                    AS occurrences,
                      l_order_recurr_plan.duration                       AS duration,
                      l_order_recurr_plan.id_unit_meas_duration          AS id_unit_meas_duration,
                      l_order_recurr_plan.end_date                       AS end_date,
                      l_order_recurr_plan.flg_status                     AS flg_status,
                      l_order_recurr_plan.id_institution                 AS id_institution,
                      l_order_recurr_plan.id_professional                AS id_professional,
                      l_order_recurr_plan.id_order_recurr_area           AS id_order_recurr_area,
                      l_order_recurr_plan.flg_include_start_date_in_plan AS flg_include_start_date_in_plan
                 FROM dual) new_vals
        ON (orp.id_order_recurr_plan = new_vals.id_order_recurr_plan)
        WHEN MATCHED THEN
            UPDATE
               SET orp.id_order_recurr_option         = new_vals.id_order_recurr_option,
                   orp.regular_interval               = new_vals.regular_interval,
                   orp.id_unit_meas_regular_interval  = new_vals.id_unit_meas_regular_interval,
                   orp.daily_executions               = new_vals.daily_executions,
                   orp.flg_recurr_pattern             = new_vals.flg_recurr_pattern,
                   orp.repeat_every                   = new_vals.repeat_every,
                   orp.flg_repeat_by                  = new_vals.flg_repeat_by,
                   orp.start_date                     = new_vals.start_date,
                   orp.flg_end_by                     = new_vals.flg_end_by,
                   orp.occurrences                    = new_vals.occurrences,
                   orp.duration                       = new_vals.duration,
                   orp.id_unit_meas_duration          = new_vals.id_unit_meas_duration,
                   orp.end_date                       = new_vals.end_date,
                   orp.flg_status                     = new_vals.flg_status,
                   orp.id_institution                 = new_vals.id_institution,
                   orp.id_professional                = new_vals.id_professional,
                   orp.id_order_recurr_area           = new_vals.id_order_recurr_area,
                   orp.flg_include_start_date_in_plan = new_vals.flg_include_start_date_in_plan
        WHEN NOT MATCHED THEN
            INSERT
                (id_order_recurr_plan,
                 id_order_recurr_option,
                 regular_interval,
                 id_unit_meas_regular_interval,
                 daily_executions,
                 flg_recurr_pattern,
                 repeat_every,
                 flg_repeat_by,
                 start_date,
                 flg_end_by,
                 occurrences,
                 duration,
                 id_unit_meas_duration,
                 end_date,
                 flg_status,
                 id_institution,
                 id_professional,
                 id_order_recurr_area,
                 flg_include_start_date_in_plan)
            VALUES
                (new_vals.id_order_recurr_plan,
                 new_vals.id_order_recurr_option,
                 new_vals.regular_interval,
                 new_vals.id_unit_meas_regular_interval,
                 new_vals.daily_executions,
                 new_vals.flg_recurr_pattern,
                 new_vals.repeat_every,
                 new_vals.flg_repeat_by,
                 new_vals.start_date,
                 new_vals.flg_end_by,
                 new_vals.occurrences,
                 new_vals.duration,
                 new_vals.id_unit_meas_duration,
                 new_vals.end_date,
                 new_vals.flg_status,
                 new_vals.id_institution,
                 new_vals.id_professional,
                 new_vals.id_order_recurr_area,
                 new_vals.flg_include_start_date_in_plan);
    
        g_error := 'prepare new records for order recurrence plan pattern table';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- prepare new records for order recurrence plan pattern table
        FOR rec_orcplp IN c_order_recurr_plan_pattern(i_order_recurr_plan, i_order_recurr_option)
        LOOP
            l_orcplp_counter := l_orcplp_counter + 1;
        
            ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan_pattern := rec_orcplp.id_order_recurr_plan_pattern;
            ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan := rec_orcplp.id_order_recurr_plan;
            ibt_order_recurr_plan_pattern(l_orcplp_counter).flg_week_day := rec_orcplp.flg_week_day;
            ibt_order_recurr_plan_pattern(l_orcplp_counter).flg_week := rec_orcplp.flg_week;
            ibt_order_recurr_plan_pattern(l_orcplp_counter).month_day := rec_orcplp.month_day;
            ibt_order_recurr_plan_pattern(l_orcplp_counter).month := rec_orcplp.month;
        END LOOP;
    
        g_error := 'insert new order recurrence plan patterns';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- insert new order recurrence plan patterns
        FORALL i IN 1 .. ibt_order_recurr_plan_pattern.count
            INSERT INTO order_recurr_plan_pattern
            VALUES ibt_order_recurr_plan_pattern
                (i);
    
        g_error := 'get all execution times configured for the default recurrence option';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get all execution times configured for the default recurrence option
        IF NOT get_order_option_executions(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_order_option           => i_order_recurr_option,
                                           o_order_option_exec_time => l_order_recurr_time,
                                           o_error                  => o_error)
        THEN
            g_error := 'error while calling get_order_option_executions function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'prepare new records for order recurrence plan time table';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- prepare new records for order recurrence plan time table
        FOR rec_orcplt IN c_order_recurr_plan_time(l_order_recurr_time, l_order_recurr_plan.id_order_recurr_plan)
        LOOP
            l_orcplt_counter := l_orcplt_counter + 1;
        
            ibt_order_recurr_plan_time(l_orcplt_counter).id_order_recurr_plan_time := rec_orcplt.id_order_recurr_plan_time;
            ibt_order_recurr_plan_time(l_orcplt_counter).id_order_recurr_plan := rec_orcplt.id_order_recurr_plan;
            ibt_order_recurr_plan_time(l_orcplt_counter).id_order_recurr_option_parent := rec_orcplt.id_order_recurr_option_parent;
            ibt_order_recurr_plan_time(l_orcplt_counter).id_order_recurr_option_child := rec_orcplt.id_order_recurr_option_child;
            ibt_order_recurr_plan_time(l_orcplt_counter).exec_time := rec_orcplt.exec_time;
            ibt_order_recurr_plan_time(l_orcplt_counter).exec_time_offset := rec_orcplt.exec_time_offset;
            ibt_order_recurr_plan_time(l_orcplt_counter).id_unit_meas_exec_time_offset := rec_orcplt.id_unit_meas_exec_time_offset;
        
        END LOOP;
    
        g_error := 'insert new order recurrence plan times';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- insert new order recurrence plan times
        FORALL i IN 1 .. ibt_order_recurr_plan_time.count
            INSERT INTO order_recurr_plan_time
            VALUES ibt_order_recurr_plan_time
                (i);
    
        g_error := 'get order recurrence instructions';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get order recurrence instructions
        IF NOT get_order_recurr_instructions(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_order_plan          => i_order_recurr_plan,
                                             o_order_recurr_desc   => o_order_recurr_desc,
                                             o_order_recurr_option => l_order_recurr_option,
                                             o_start_date          => l_new_start_date,
                                             o_occurrences         => l_new_occurrences,
                                             o_duration            => l_new_duration,
                                             o_unit_meas_duration  => l_new_unit_meas_duration,
                                             o_end_date            => l_new_end_date,
                                             o_flg_end_by_editable => o_flg_end_by_editable,
                                             o_error               => o_error)
        THEN
            g_error := 'error while calling get_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'update order recurrence plan with the new order recurrence instructions';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- update order recurrence plan with the new order recurrence instructions
        UPDATE order_recurr_plan orcpl
           SET orcpl.start_date            = l_new_start_date,
               orcpl.occurrences           = decode(l_new_rec_order_recurr_plan.flg_end_by,
                                                    g_flg_end_by_occurrences,
                                                    l_new_occurrences),
               orcpl.duration              = decode(l_new_rec_order_recurr_plan.flg_end_by,
                                                    g_flg_end_by_duration,
                                                    l_new_duration),
               orcpl.id_unit_meas_duration = decode(l_new_rec_order_recurr_plan.flg_end_by,
                                                    g_flg_end_by_duration,
                                                    l_new_unit_meas_duration),
               orcpl.end_date              = decode(l_new_rec_order_recurr_plan.flg_end_by,
                                                    g_flg_end_by_date,
                                                    l_new_end_date)
         WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan;
    
        -- set output parameters with the new order recurrence instructions
        o_order_recurr_desc   := get_order_recurr_pfreq_desc(i_lang, i_prof, i_order_recurr_plan);
        o_start_date          := l_new_start_date;
        o_occurrences         := l_new_occurrences;
        o_duration            := l_new_duration;
        o_unit_meas_duration  := nvl(l_new_unit_meas_duration, g_unit_measure_day); -- if not defined, the default unit should be in days
        o_end_date := CASE
                          WHEN i_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_once THEN
                           NULL
                          ELSE
                           l_new_end_date
                      END;
        o_flg_end_by_editable := check_end_date_set(i_order_recurr_plan);
    
        RETURN TRUE;
    EXCEPTION
        WHEN dml_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_OPTION',
                                              o_error);
            RETURN FALSE;
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
    ) RETURN BOOLEAN IS
    
        -- auxiliary local variable
    
        l_new_start_date         order_recurr_plan.start_date%TYPE;
        l_new_occurrences        order_recurr_plan.occurrences%TYPE;
        l_new_duration           order_recurr_plan.duration%TYPE;
        l_new_unit_meas_duration order_recurr_plan.id_unit_meas_duration%TYPE;
        l_new_end_date           order_recurr_plan.end_date%TYPE;
    
        l_flg_end_by order_recurr_plan.flg_end_by%TYPE;
    
        l_recurr_pattern order_recurr_plan.flg_recurr_pattern%TYPE;
        l_occurrences    order_recurr_plan.occurrences%TYPE;
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        CURSOR c_order_recurr_plan IS
            SELECT orcpl.id_order_recurr_option
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
               AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined);
    
        l_order_recurr_option order_recurr_plan.id_order_recurr_option%TYPE;
    
        -- process "end by" field value
        FUNCTION get_flg_end_by RETURN order_recurr_plan.flg_end_by%TYPE IS
            l_flg_end_by order_recurr_plan.flg_end_by%TYPE;
        BEGIN
        
            CASE
                WHEN i_occurrences IS NOT NULL THEN
                    l_flg_end_by := g_flg_end_by_occurrences;
                WHEN i_duration IS NOT NULL THEN
                    l_flg_end_by := g_flg_end_by_duration;
                WHEN i_end_date IS NOT NULL THEN
                    l_flg_end_by := g_flg_end_by_date;
                ELSE
                    l_flg_end_by := g_flg_end_by_no_end;
            END CASE;
        
            RETURN l_flg_end_by;
        
        END get_flg_end_by;
    
    BEGIN
        -- get record from order_recurr_plan table
        g_error := 'get record from order_recurr_plan table, where id_order_recurr_plan is [' || i_order_recurr_plan || ']';
        pk_alertlog.log_debug(g_error, g_package_name);
        OPEN c_order_recurr_plan;
        FETCH c_order_recurr_plan
            INTO l_order_recurr_option;
        CLOSE c_order_recurr_plan;
    
        g_error := 'update order recurrence plan with the instructions defined by the user';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF l_order_recurr_option != g_order_recurr_option_once
        THEN
            l_occurrences := i_occurrences;
            l_flg_end_by  := get_flg_end_by(); -- get "end by" field value
        ELSE
            l_occurrences := NULL; -- clear occurrences field when the pattern is "once" (to avoid the occurrences workflow)
        END IF;
    
        -- update order recurrence plan with the instructions defined by the user
        UPDATE order_recurr_plan orcpl
           SET orcpl.start_date            = trunc_timestamp_to_minutes(i_lang, i_prof, nvl(i_start_date, l_sysdate)),
               orcpl.occurrences           = decode(l_flg_end_by, g_flg_end_by_occurrences, l_occurrences),
               orcpl.duration              = decode(l_flg_end_by, g_flg_end_by_duration, i_duration),
               orcpl.id_unit_meas_duration = decode(l_flg_end_by, g_flg_end_by_duration, i_unit_meas_duration),
               orcpl.end_date              = decode(l_flg_end_by, g_flg_end_by_date, i_end_date),
               orcpl.flg_end_by            = l_flg_end_by
         WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
           AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined)
        RETURNING orcpl.flg_recurr_pattern INTO l_recurr_pattern;
    
        -- if number of ocurrences, duration or end date were defined by the user and
        -- this plan has no recurrence pattern, then set daily recurrence pattern
        IF l_recurr_pattern = g_flg_recurr_pattern_none
           AND (l_occurrences IS NOT NULL OR i_duration IS NOT NULL OR i_end_date IS NOT NULL)
        THEN
        
            -- set daily recurrence pattern
            UPDATE order_recurr_plan orcpl
               SET orcpl.flg_recurr_pattern = g_flg_recurr_pattern_daily, orcpl.repeat_every = 1
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
               AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined);
        
        END IF;
    
        -- check if the recurrence plan is in temporary status
        IF SQL%ROWCOUNT = 0
        THEN
            g_error := 'Order recurrence plan id does not exist or it is not in a temporary status';
            RETURN TRUE;
            --RAISE e_user_exception;
        END IF;
    
        g_error := 'get new order recurrence instructions';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get new order recurrence instructions
        IF NOT get_order_recurr_instructions(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_order_plan          => i_order_recurr_plan,
                                             o_order_recurr_desc   => o_order_recurr_desc,
                                             o_order_recurr_option => o_order_recurr_option,
                                             o_start_date          => l_new_start_date,
                                             o_occurrences         => l_new_occurrences,
                                             o_duration            => l_new_duration,
                                             o_unit_meas_duration  => l_new_unit_meas_duration,
                                             o_end_date            => l_new_end_date,
                                             o_flg_end_by_editable => o_flg_end_by_editable,
                                             o_error               => o_error)
        THEN
            g_error := 'error while calling get_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'update order recurrence plan with the new order recurrence instructions';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- update order recurrence plan with the new order recurrence instructions
        UPDATE order_recurr_plan orcpl
           SET orcpl.start_date            = nvl(i_start_date, l_sysdate), --l_new_start_date,
               orcpl.occurrences           = decode(l_flg_end_by, g_flg_end_by_occurrences, l_new_occurrences),
               orcpl.duration              = decode(l_flg_end_by, g_flg_end_by_duration, l_new_duration),
               orcpl.id_unit_meas_duration = decode(l_flg_end_by, g_flg_end_by_duration, l_new_unit_meas_duration),
               orcpl.end_date              = decode(l_flg_end_by, g_flg_end_by_date, l_new_end_date)
         WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan;
    
        -- set output parameters with the new order recurrence instructions
        o_start_date         := i_start_date; --l_new_start_date;
        o_occurrences        := l_new_occurrences;
        o_duration           := l_new_duration;
        o_unit_meas_duration := nvl(l_new_unit_meas_duration, g_unit_measure_day); -- if not defined, the default unit should be in days
        o_end_date           := l_new_end_date;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ORDER_RECURR_INSTRUCTIONS',
                                              o_error);
            RETURN FALSE;
    END set_order_recurr_instructions;

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
    ) RETURN BOOLEAN IS
    
        -- auxiliary local variables
        l_order_recurr_area order_recurr_area.id_order_recurr_area%TYPE;
    
        l_orcplt_counter PLS_INTEGER := 0;
        TYPE t_order_recurr_plan_time IS TABLE OF order_recurr_plan_time%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_order_recurr_plan_time t_order_recurr_plan_time;
    
        l_orcplp_counter PLS_INTEGER := 0;
        TYPE t_order_recurr_plan_pattern IS TABLE OF order_recurr_plan_pattern%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_order_recurr_plan_pattern t_order_recurr_plan_pattern;
    
        l_new_start_date         order_recurr_plan.start_date%TYPE;
        l_new_occurrences        order_recurr_plan.occurrences%TYPE;
        l_new_duration           order_recurr_plan.duration%TYPE;
        l_new_unit_meas_duration order_recurr_plan.id_unit_meas_duration%TYPE;
        l_new_end_date           order_recurr_plan.end_date%TYPE;
    
        l_order_recurr_option order_recurr_option.id_order_recurr_option%TYPE;
    
        l_flg_status order_recurr_plan.flg_status%TYPE;
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_edit NUMBER := 0;
    
        -- generate new order recurrence plan time id
        FUNCTION get_new_orcplt_id RETURN order_recurr_plan_time.id_order_recurr_plan_time%TYPE IS
            l_new_orcplt_id order_recurr_plan_time.id_order_recurr_plan_time%TYPE;
        BEGIN
        
            SELECT seq_order_recurr_plan_time.nextval
              INTO l_new_orcplt_id
              FROM dual;
        
            RETURN l_new_orcplt_id;
        
        END get_new_orcplt_id;
    
        -- generate new order recurrence plan pattern id
        FUNCTION get_new_orcplp_id RETURN order_recurr_plan_pattern.id_order_recurr_plan_pattern%TYPE IS
            l_new_orcplp_id order_recurr_plan_pattern.id_order_recurr_plan_pattern%TYPE;
        BEGIN
        
            SELECT seq_order_recurr_plan_pattern.nextval
              INTO l_new_orcplp_id
              FROM dual;
        
            RETURN l_new_orcplp_id;
        
        END get_new_orcplp_id;
    
    BEGIN
    
        g_error := 'get order recurrence area of the previous plan';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get order recurrence area of the previous plan
        BEGIN
            SELECT orcpl.id_order_recurr_area, orcpl.flg_status
              INTO l_order_recurr_area, l_flg_status
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
               AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined);
        EXCEPTION
            WHEN no_data_found THEN
                BEGIN
                    SELECT orcpl.id_order_recurr_area, orcpl.flg_status
                      INTO l_order_recurr_area, l_flg_status
                      FROM order_recurr_plan orcpl
                     WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
                       AND orcpl.flg_status NOT IN (g_plan_status_temp, g_plan_status_predefined);
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := 'Order recurrence plan id does not exist or it is not in a temporary or predefined status';
                        RAISE e_user_exception;
                END;
            
                l_edit := 1;
            
        END;
    
        g_error := 'delete previous order recurrence plan data';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF l_edit = 0
        THEN
            IF NOT cancel_order_recurr_plan(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_order_recurr_plan => i_order_recurr_plan,
                                            i_flg_persist_plan  => pk_alert_constant.g_yes,
                                            o_error             => o_error)
            THEN
                g_error := 'error while calling cancel_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        END IF;
    
        g_error := 'insert new order recurrence plan';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- insert/update new order recurrence plan
        MERGE INTO order_recurr_plan orp
        USING (SELECT i_order_recurr_plan          AS id_order_recurr_plan,
                      g_order_recurr_option_other  AS id_order_recurr_option,
                      i_regular_interval           AS regular_interval,
                      i_unit_meas_regular_interval AS id_unit_meas_regular_interval,
                      i_daily_executions           AS daily_executions,
                      i_flg_recurr_pattern         AS flg_recurr_pattern,
                      i_repeat_every               AS repeat_every,
                      i_flg_repeat_by              AS flg_repeat_by,
                      --decode(i_start_date, null, null, trunc_timestamp_to_minutes(i_lang, i_prof, i_start_date)) AS start_date,
                      trunc_timestamp_to_minutes(i_lang, i_prof, nvl(i_start_date, l_sysdate)) AS start_date,
                      i_flg_end_by AS flg_end_by,
                      i_occurrences AS occurrences,
                      i_duration AS duration,
                      i_unit_meas_duration AS id_unit_meas_duration,
                      i_end_date AS end_date,
                      l_flg_status AS flg_status,
                      i_prof.institution AS id_institution,
                      i_prof.id AS id_professional,
                      l_order_recurr_area AS id_order_recurr_area
                 FROM dual) new_vals
        ON (orp.id_order_recurr_plan = new_vals.id_order_recurr_plan)
        WHEN MATCHED THEN
            UPDATE
               SET orp.id_order_recurr_option        = new_vals.id_order_recurr_option,
                   orp.regular_interval              = new_vals.regular_interval,
                   orp.id_unit_meas_regular_interval = new_vals.id_unit_meas_regular_interval,
                   orp.daily_executions              = new_vals.daily_executions,
                   orp.flg_recurr_pattern            = new_vals.flg_recurr_pattern,
                   orp.repeat_every                  = new_vals.repeat_every,
                   orp.flg_repeat_by                 = new_vals.flg_repeat_by,
                   orp.start_date                    = new_vals.start_date,
                   orp.flg_end_by                    = new_vals.flg_end_by,
                   orp.occurrences                   = new_vals.occurrences,
                   orp.duration                      = new_vals.duration,
                   orp.id_unit_meas_duration         = new_vals.id_unit_meas_duration,
                   orp.end_date                      = new_vals.end_date,
                   orp.flg_status                    = new_vals.flg_status,
                   orp.id_institution                = new_vals.id_institution,
                   orp.id_professional               = new_vals.id_professional,
                   orp.id_order_recurr_area          = new_vals.id_order_recurr_area
        WHEN NOT MATCHED THEN
            INSERT
                (id_order_recurr_plan,
                 id_order_recurr_option,
                 regular_interval,
                 id_unit_meas_regular_interval,
                 daily_executions,
                 flg_recurr_pattern,
                 repeat_every,
                 flg_repeat_by,
                 start_date,
                 flg_end_by,
                 occurrences,
                 duration,
                 id_unit_meas_duration,
                 end_date,
                 flg_status,
                 id_institution,
                 id_professional,
                 id_order_recurr_area)
            VALUES
                (new_vals.id_order_recurr_plan,
                 new_vals.id_order_recurr_option,
                 new_vals.regular_interval,
                 new_vals.id_unit_meas_regular_interval,
                 new_vals.daily_executions,
                 new_vals.flg_recurr_pattern,
                 new_vals.repeat_every,
                 new_vals.flg_repeat_by,
                 new_vals.start_date,
                 new_vals.flg_end_by,
                 new_vals.occurrences,
                 new_vals.duration,
                 new_vals.id_unit_meas_duration,
                 new_vals.end_date,
                 new_vals.flg_status,
                 new_vals.id_institution,
                 new_vals.id_professional,
                 new_vals.id_order_recurr_area);
    
        g_error := 'prepare new records for order recurrence plan time table';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- prepare new records for order recurrence plan time table
        FOR i IN 1 .. i_exec_time_parent_option.count
        LOOP
        
            -- ignore record if no execution time is defined
            IF i_exec_time(i) IS NOT NULL
            THEN
                l_orcplt_counter := l_orcplt_counter + 1;
            
                ibt_order_recurr_plan_time(l_orcplt_counter).id_order_recurr_plan_time := get_new_orcplt_id();
                ibt_order_recurr_plan_time(l_orcplt_counter).id_order_recurr_plan := i_order_recurr_plan;
                ibt_order_recurr_plan_time(l_orcplt_counter).id_order_recurr_option_parent := i_exec_time_parent_option(i);
                ibt_order_recurr_plan_time(l_orcplt_counter).id_order_recurr_option_child := i_exec_time_option(i);
                ibt_order_recurr_plan_time(l_orcplt_counter).exec_time := decode_exec_time(i_lang,
                                                                                           i_prof,
                                                                                           i_exec_time(i),
                                                                                           i_exec_time_offset(i),
                                                                                           i_unit_meas_exec_time_offset(i));
                ibt_order_recurr_plan_time(l_orcplt_counter).exec_time_offset := i_exec_time_offset(i);
                ibt_order_recurr_plan_time(l_orcplt_counter).id_unit_meas_exec_time_offset := i_unit_meas_exec_time_offset(i);
            END IF;
        
        END LOOP;
    
        g_error := 'insert new order recurrence plan times';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- insert new order recurrence plan times
        FORALL i IN 1 .. ibt_order_recurr_plan_time.count
            INSERT INTO order_recurr_plan_time
            VALUES ibt_order_recurr_plan_time
                (i);
    
        g_error := 'prepare new records for order recurrence plan pattern table';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- prepare new records for order recurrence plan pattern table
        -- week days records
        FOR i IN 1 .. i_flg_week_day.count
        LOOP
            IF i_flg_week_day(i) IS NOT NULL
            THEN
                l_orcplp_counter := l_orcplp_counter + 1;
            
                ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan_pattern := get_new_orcplp_id();
                ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan := i_order_recurr_plan;
                ibt_order_recurr_plan_pattern(l_orcplp_counter).flg_week_day := i_flg_week_day(i);
            END IF;
        END LOOP;
    
        -- weeks records
        FOR i IN 1 .. i_flg_week.count
        LOOP
            IF i_flg_week(i) IS NOT NULL
            THEN
                l_orcplp_counter := l_orcplp_counter + 1;
            
                ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan_pattern := get_new_orcplp_id();
                ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan := i_order_recurr_plan;
                ibt_order_recurr_plan_pattern(l_orcplp_counter).flg_week := i_flg_week(i);
            END IF;
        END LOOP;
    
        -- month days records
        FOR i IN 1 .. i_month_day.count
        LOOP
            IF i_month_day(i) IS NOT NULL
            THEN
                l_orcplp_counter := l_orcplp_counter + 1;
            
                ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan_pattern := get_new_orcplp_id();
                ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan := i_order_recurr_plan;
                ibt_order_recurr_plan_pattern(l_orcplp_counter).month_day := i_month_day(i);
            END IF;
        END LOOP;
    
        -- months records
        FOR i IN 1 .. i_month.count
        LOOP
            IF i_month(i) IS NOT NULL
            THEN
                l_orcplp_counter := l_orcplp_counter + 1;
            
                ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan_pattern := get_new_orcplp_id();
                ibt_order_recurr_plan_pattern(l_orcplp_counter).id_order_recurr_plan := i_order_recurr_plan;
                ibt_order_recurr_plan_pattern(l_orcplp_counter).month := i_month(i);
            END IF;
        END LOOP;
    
        g_error := 'insert new order recurrence plan patterns';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- insert new order recurrence plan patterns
        FORALL i IN 1 .. ibt_order_recurr_plan_pattern.count
            INSERT INTO order_recurr_plan_pattern
            VALUES ibt_order_recurr_plan_pattern
                (i);
    
        g_error := 'get order recurrence instructions';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get order recurrence instructions
        IF NOT get_order_recurr_instructions(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_order_plan          => i_order_recurr_plan,
                                             o_order_recurr_desc   => o_order_recurr_desc,
                                             o_order_recurr_option => l_order_recurr_option,
                                             o_start_date          => l_new_start_date,
                                             o_occurrences         => l_new_occurrences,
                                             o_duration            => l_new_duration,
                                             o_unit_meas_duration  => l_new_unit_meas_duration,
                                             o_end_date            => l_new_end_date,
                                             o_flg_end_by_editable => o_flg_end_by_editable,
                                             o_error               => o_error)
        THEN
            g_error := 'error while calling get_order_recurr_instructions function';
            RAISE e_user_exception;
        END IF;
    
        g_error := 'update order recurrence plan with the new order recurrence instructions';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- update order recurrence plan with the new order recurrence instructions
        IF l_new_end_date IS NOT NULL
           OR i_flg_end_by != g_flg_end_by_date
        THEN
            UPDATE order_recurr_plan orcpl
               SET orcpl.start_date            = l_new_start_date,
                   orcpl.occurrences           = decode(i_flg_end_by, g_flg_end_by_occurrences, l_new_occurrences),
                   orcpl.duration              = decode(i_flg_end_by, g_flg_end_by_duration, l_new_duration),
                   orcpl.id_unit_meas_duration = decode(i_flg_end_by,
                                                        g_flg_end_by_duration,
                                                        -- if not defined, the default unit should be in days
                                                        nvl(l_new_unit_meas_duration, g_unit_measure_day)),
                   orcpl.end_date              = decode(i_flg_end_by, g_flg_end_by_date, l_new_end_date)
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
            -- set output parameters with the new order recurrence instructions
            RETURNING orcpl.start_date, orcpl.occurrences, orcpl.duration, orcpl.id_unit_meas_duration INTO o_start_date, o_occurrences, o_duration, o_unit_meas_duration;
        ELSE
            UPDATE order_recurr_plan orcpl
               SET orcpl.start_date = l_new_start_date
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan;
        
            o_start_date := l_new_start_date;
        END IF;
        -- if number of ocurrences, duration or end date were defined by the user and
        -- this plan has no recurrence pattern, then set daily recurrence pattern
        IF i_flg_recurr_pattern = g_flg_recurr_pattern_none
           AND (i_occurrences IS NOT NULL OR i_duration IS NOT NULL OR i_end_date IS NOT NULL OR
           i_flg_end_by = g_flg_end_by_no_end)
        THEN
        
            -- set daily recurrence pattern
            UPDATE order_recurr_plan orcpl
               SET orcpl.flg_recurr_pattern = g_flg_recurr_pattern_daily, orcpl.repeat_every = 1
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
               AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined);
        
        END IF;
    
        -- even if the recurrence plan is not base on duration, the unit measure should be returned, so it can be available
        IF o_unit_meas_duration IS NULL
        THEN
            o_unit_meas_duration := g_unit_measure_day;
        END IF;
    
        o_end_date := l_new_end_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN dml_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_OTHER_ORDER_RECURR_OPTION',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_OTHER_ORDER_RECURR_OPTION',
                                              o_error);
            RETURN FALSE;
    END set_other_order_recurr_option;

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
    
        l_order_recurr_option order_recurr_option.id_order_recurr_option%TYPE;
        l_order_recurr_area   order_recurr_area.id_order_recurr_area%TYPE;
    
    BEGIN
        g_error := 'get order recurrence option of this plan';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get order recurrence option of this plan
        BEGIN
            SELECT orcpl.id_order_recurr_option, orcpl.id_order_recurr_area
              INTO l_order_recurr_option, l_order_recurr_area
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
               AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined);
        EXCEPTION
            WHEN no_data_found THEN
            
                BEGIN
                    SELECT orcpl.id_order_recurr_option, orcpl.id_order_recurr_area
                      INTO l_order_recurr_option, l_order_recurr_area
                      FROM order_recurr_plan orcpl
                     WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
                       AND orcpl.flg_status = g_plan_status_final;
                
                    o_final_order_recurr_plan := i_order_recurr_plan;
                
                    RETURN TRUE;
                EXCEPTION
                    WHEN no_data_found THEN
                    
                        g_error := 'Order recurrence plan id does not exist or it is not in a temporary or predefined status';
                        RETURN TRUE;
                        --RAISE e_user_exception;
                END;
        END;
    
        g_error := 'check if there is recurrence or not for this order';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- if there is no recurrence, the temporary order recurrence plan must be cancelled
        -- and no order recurrence plan id must be returned
        IF (l_order_recurr_option = g_order_recurr_option_once AND
           l_order_recurr_area NOT IN (g_area_nnn_noc_outcome, g_area_nnn_noc_indicator, g_area_nnn_nic_activity))
        THEN
        
            g_error := 'cancel temporary order recurrence plan';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- cancel temporary order recurrence plan
            IF NOT pk_order_recurrence_core.cancel_order_recurr_plan(i_lang              => i_lang,
                                                                     i_prof              => i_prof,
                                                                     i_order_recurr_plan => i_order_recurr_plan,
                                                                     o_error             => o_error)
            THEN
                g_error := 'error while calling cancel_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        
            -- doesn't return order recurrence plan id
            o_final_order_recurr_plan := NULL;
        
        ELSE
        
            g_error := 'set order recurrence plan as definitive';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- set order recurrence plan as definitive
            UPDATE order_recurr_plan orcpl
               SET orcpl.flg_status = g_plan_status_final
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
               AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined);
        
            -- set final order recurrence plan id
            o_final_order_recurr_plan := i_order_recurr_plan;
        
        END IF;
    
        -- set output parameter with order recurrence option id
        o_order_recurr_option := l_order_recurr_option;
    
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
    * cancel a temporary or predefined order recurrence plan
    *
    * @param       i_lang                   preferred language id
    * @param       i_prof                   professional structure
    * @param       i_order_recurr_plan      order recurrence plan id
    * @param       i_flg_persist_plan       flag that indicates if order recurrence plan id should persist or not
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
    ) RETURN BOOLEAN IS
        l_order_recurr_plan_status order_recurr_plan.flg_status%TYPE;
    BEGIN
    
        -- check if the recurrence plan is in temporary status
        g_error := 'check order recurrence plan status';
        BEGIN
            SELECT orcpl.flg_status
              INTO l_order_recurr_plan_status
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan
               AND orcpl.flg_status IN (g_plan_status_temp, g_plan_status_predefined);
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'Order recurrence plan id does not exist or it is not in a temporary or predefined status';
                RAISE e_user_exception;
        END;
    
        g_error := 'delete records from ORDER_RECURR_PLAN_TIME table';
        DELETE FROM order_recurr_plan_time orcplt
         WHERE orcplt.id_order_recurr_plan = i_order_recurr_plan;
    
        g_error := 'delete records from ORDER_RECURR_PLAN_PATTERN table';
        DELETE FROM order_recurr_plan_pattern orcplp
         WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan;
    
        g_error := 'delete records from ORDER_RECURR_PLAN_PATTERN table';
        DELETE FROM order_recurr_control orc
         WHERE orc.id_order_recurr_plan = i_order_recurr_plan;
    
        -- check if order recurrence plan id should persist or not
        IF i_flg_persist_plan = pk_alert_constant.g_no
        THEN
        
            g_error := 'delete record from ORDER_RECURR_PLAN table';
            UPDATE interv_presc_det
               SET id_order_recurrence = NULL
             WHERE id_order_recurrence = i_order_recurr_plan;
        
            UPDATE blood_product_det
               SET id_order_recurrence = NULL
             WHERE id_order_recurrence = i_order_recurr_plan;
        
            DELETE FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan;
        
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
                                              'CANCEL_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END cancel_order_recurr_plan;

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
    ) RETURN BOOLEAN IS
    
        -- auxiliary local variables
        l_order_recurr_option order_recurr_option.id_order_recurr_option%TYPE;
    
        l_exec_time_parent_option    table_number;
        l_exec_time_option           table_number;
        l_exec_time                  table_varchar;
        l_exec_time_offset           table_number;
        l_unit_meas_exec_time_offset table_number;
    
        l_predef_time_sched table_number;
    
        l_exec_times t_tbl_recurr_exec_times;
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        g_error := 'get order recurrence plan data';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        BEGIN
            SELECT orcpl.id_order_recurr_option,
                   orcpl.regular_interval,
                   orcpl.id_unit_meas_regular_interval,
                   orcpl.daily_executions,
                   orcpl.flg_recurr_pattern,
                   orcpl.repeat_every,
                   decode(orcpl.flg_recurr_pattern,
                          g_flg_recurr_pattern_daily,
                          g_unit_measure_day,
                          g_flg_recurr_pattern_weekly,
                          g_unit_measure_week,
                          g_flg_recurr_pattern_monthly,
                          g_unit_measure_month,
                          g_flg_recurr_pattern_yearly,
                          g_unit_measure_year) AS unit_meas_repeat_every,
                   orcpl.flg_repeat_by,
                   orcpl.start_date,
                   orcpl.flg_end_by,
                   orcpl.occurrences,
                   orcpl.duration,
                   orcpl.id_unit_meas_duration,
                   orcpl.end_date
              INTO l_order_recurr_option,
                   o_regular_interval,
                   o_unit_meas_regular_interval,
                   o_daily_executions,
                   o_flg_recurr_pattern,
                   o_repeat_every,
                   o_unit_meas_repeat_every,
                   o_flg_repeat_by,
                   o_start_date,
                   o_flg_end_by,
                   o_occurrences,
                   o_duration,
                   o_unit_meas_duration,
                   o_end_date
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_order_recurr_plan;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'Order recurrence plan id does not exist';
                RAISE e_user_exception;
        END;
        g_error := 'get execution times data';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT orcplt.id_order_recurr_option_parent AS exec_time_parent_option,
               orcplt.id_order_recurr_option_child AS exec_time_option,
               encode_exec_time(i_lang,
                                i_prof,
                                add_offset_to_tstz(orcplt.exec_time_offset,
                                                   get_timestamp_day_tstz(i_lang, i_prof, l_sysdate) + orcplt.exec_time,
                                                   orcplt.id_unit_meas_exec_time_offset)) AS exec_time,
               orcplt.exec_time_offset AS exec_time_offset,
               orcplt.id_unit_meas_exec_time_offset AS unit_meas_exec_time_offset
          BULK COLLECT
          INTO l_exec_time_parent_option,
               l_exec_time_option,
               l_exec_time,
               l_exec_time_offset,
               l_unit_meas_exec_time_offset
          FROM order_recurr_plan_time orcplt
         WHERE orcplt.id_order_recurr_plan = i_order_recurr_plan
         ORDER BY exec_time;
    
        g_error := 'get predefined time schedules ids';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT DISTINCT exec_time_parents.column_value
          BULK COLLECT
          INTO l_predef_time_sched
          FROM TABLE(l_exec_time_parent_option) exec_time_parents
         WHERE exec_time_parents.column_value IS NOT NULL;
    
        g_error := 'get recurrence pattern data';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- only get order recurrence plan parameters if edited plan is -1 (other frequency)
        IF l_order_recurr_option = g_order_recurr_option_other
        THEN
            -- week day options
            SELECT orcplp.flg_week_day
              BULK COLLECT
              INTO o_flg_week_day
              FROM order_recurr_plan_pattern orcplp
             WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
               AND orcplp.flg_week_day IS NOT NULL;
        
            -- week options
            SELECT orcplp.flg_week
              BULK COLLECT
              INTO o_flg_week
              FROM order_recurr_plan_pattern orcplp
             WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
               AND orcplp.flg_week IS NOT NULL;
        
            -- month day options
            SELECT orcplp.month_day
              BULK COLLECT
              INTO o_month_day
              FROM order_recurr_plan_pattern orcplp
             WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
               AND orcplp.month_day IS NOT NULL;
        
            -- month options
            SELECT orcplp.month
              BULK COLLECT
              INTO o_month
              FROM order_recurr_plan_pattern orcplp
             WHERE orcplp.id_order_recurr_plan = i_order_recurr_plan
               AND orcplp.month IS NOT NULL;
        ELSE
            o_predef_time_sched := NULL;
            o_flg_week_day      := NULL;
            o_flg_week          := NULL;
            o_month_day         := NULL;
            o_month             := NULL;
        END IF;
    
        g_error := 'check order recurrence parameters';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT check_other_recurr_option(i_lang                       => i_lang,
                                         i_prof                       => i_prof,
                                         i_order_recurr_plan          => i_order_recurr_plan,
                                         i_edit_field_name            => NULL,
                                         i_regular_interval           => o_regular_interval,
                                         i_unit_meas_regular_interval => o_unit_meas_regular_interval,
                                         i_daily_executions           => o_daily_executions,
                                         i_predef_time_sched          => l_predef_time_sched,
                                         i_exec_time_parent_option    => l_exec_time_parent_option,
                                         i_exec_time_option           => l_exec_time_option,
                                         i_exec_time                  => l_exec_time,
                                         i_exec_time_offset           => l_exec_time_offset,
                                         i_unit_meas_exec_time_offset => l_unit_meas_exec_time_offset,
                                         i_flg_recurr_pattern         => o_flg_recurr_pattern,
                                         i_repeat_every               => o_repeat_every,
                                         i_flg_repeat_by              => o_flg_repeat_by,
                                         i_start_date                 => o_start_date,
                                         i_flg_end_by                 => o_flg_end_by,
                                         i_occurrences                => o_occurrences,
                                         i_duration                   => o_duration,
                                         i_unit_meas_duration         => o_unit_meas_duration,
                                         i_end_date                   => o_end_date,
                                         i_flg_week_day               => o_flg_week_day,
                                         i_flg_week                   => o_flg_week,
                                         i_month_day                  => o_month_day,
                                         i_month                      => o_month,
                                         i_flg_context                => i_flg_context,
                                         o_regular_interval           => o_regular_interval,
                                         o_unit_meas_regular_interval => o_unit_meas_regular_interval,
                                         o_daily_executions           => o_daily_executions,
                                         o_predef_time_sched          => o_predef_time_sched,
                                         o_exec_times                 => o_exec_times,
                                         o_flg_recurr_pattern         => o_flg_recurr_pattern,
                                         o_repeat_every               => o_repeat_every,
                                         o_unit_meas_repeat_every     => o_unit_meas_repeat_every,
                                         o_flg_repeat_by              => o_flg_repeat_by,
                                         o_start_date                 => o_start_date,
                                         o_flg_end_by                 => o_flg_end_by,
                                         o_occurrences                => o_occurrences,
                                         o_duration                   => o_duration,
                                         o_unit_meas_duration         => o_unit_meas_duration,
                                         o_end_date                   => o_end_date,
                                         o_flg_week_day               => o_flg_week_day,
                                         o_flg_week                   => o_flg_week,
                                         o_month_day                  => o_month_day,
                                         o_month                      => o_month,
                                         o_flg_regular_interval_edit  => o_flg_regular_interval_edit,
                                         o_flg_daily_executions_edit  => o_flg_daily_executions_edit,
                                         o_flg_predef_time_sched_edit => o_flg_predef_time_sched_edit,
                                         o_flg_exec_time_edit         => o_flg_exec_time_edit,
                                         o_flg_repeat_every_edit      => o_flg_repeat_every_edit,
                                         o_flg_repeat_by_edit         => o_flg_repeat_by_edit,
                                         o_flg_start_date_edit        => o_flg_start_date_edit,
                                         o_flg_end_by_edit            => o_flg_end_by_edit,
                                         o_flg_end_after_edit         => o_flg_end_after_edit,
                                         o_flg_week_day_edit          => o_flg_week_day_edit,
                                         o_flg_week_edit              => o_flg_week_edit,
                                         o_flg_month_day_edit         => o_flg_month_day_edit,
                                         o_flg_month_edit             => o_flg_month_edit,
                                         o_flg_ok_avail               => o_flg_ok_avail,
                                         o_error                      => o_error)
        THEN
            g_error := 'Error found while calling check_other_recurr_option function';
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
                                              'GET_OTHER_ORDER_RECURR_OPTION',
                                              o_error);
            RETURN FALSE;
    END get_other_order_recurr_option;

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
    ) RETURN BOOLEAN IS
        k_minute_format CONSTANT pk_types.t_low_char := 'MI';
        -- auxiliary local variables
        l_orcplt_exec_times   t_tbl_orcplt := t_tbl_orcplt();
        l_orcotmsi_exec_times t_tbl_orcotmsi := t_tbl_orcotmsi();
    
        l_exec_times_count PLS_INTEGER := 0;
    
        l_previous_exec_time VARCHAR2(30 CHAR);
    
        l_flg_exec_times_ok VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    
        l_id_order_recurr_area order_recurr_plan.id_order_recurr_area%TYPE;
        l_id_market            market.id_market%TYPE;
        l_interval             order_recurr_control_cfg.interval_value%TYPE;
    
        l_start_date    order_recurr_plan.start_date%TYPE := i_start_date;
        l_end_date      order_recurr_plan.end_date%TYPE := i_end_date;
        l_sysdate       TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_sysdate_trunc TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- Current timestamp truncated to the minute
        l_sysdate_trunc := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                            i_timestamp => l_sysdate,
                                                            i_format    => k_minute_format);
    
        -- Prevents an invalid truncated date be null, just in case.
        l_sysdate_trunc := coalesce(l_sysdate_trunc, l_sysdate);
    
        g_error := 'get market id';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        g_error := 'get order recurrence area id';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT orp.id_order_recurr_area
          INTO l_id_order_recurr_area
          FROM order_recurr_plan orp
         WHERE orp.id_order_recurr_plan = i_order_recurr_plan;
    
        g_error := 'check daily frequency parameters';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_edit_field_name = g_edit_field_regular_intervals AND i_regular_interval IS NOT NULL)
           OR (i_edit_field_name NOT IN (g_edit_field_daily_executions, g_edit_field_predef_sched) AND
           instr(i_edit_field_name, g_edit_field_exact_time) = 0 AND i_regular_interval IS NOT NULL)
           OR (i_edit_field_name IS NULL AND i_regular_interval IS NOT NULL)
        THEN
            g_error := 'regular intervals';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- set fields values
            o_regular_interval           := i_regular_interval;
            o_unit_meas_regular_interval := nvl(i_unit_meas_regular_interval, g_unit_measure_hour);
            o_daily_executions           := NULL;
            o_predef_time_sched          := NULL;
        
            -- set fields enabled/disabled
            o_flg_regular_interval_edit  := pk_alert_constant.g_yes;
            o_flg_daily_executions_edit  := pk_alert_constant.g_yes;
            o_flg_predef_time_sched_edit := pk_alert_constant.g_yes;
            o_flg_exec_time_edit         := pk_alert_constant.g_yes;
        
            o_flg_recurr_pattern := g_flg_recurr_pattern_none;
        
            o_flg_repeat_every_edit  := pk_alert_constant.g_no;
            o_unit_meas_repeat_every := g_unit_measure_day;
            o_flg_repeat_by          := NULL;
        
            IF l_start_date IS NULL
            THEN
                o_start_date := NULL;
            ELSE
                o_start_date := trunc_timestamp_to_minutes(i_lang, i_prof, l_start_date);
            END IF;
        
            o_flg_end_by := i_flg_end_by;
            o_month      := NULL;
        
            IF l_start_date IS NULL
            THEN
                o_flg_start_date_edit := pk_alert_constant.g_no;
            ELSE
                o_flg_start_date_edit := pk_alert_constant.g_yes;
            END IF;
        
            o_flg_end_by_edit := pk_alert_constant.g_yes;
        
        ELSIF (i_daily_executions IS NOT NULL OR (i_predef_time_sched IS NOT NULL AND i_predef_time_sched.count > 0) OR
              instr(i_edit_field_name, g_edit_field_exact_time) != 0)
        THEN
            g_error := 'daily executions';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- set fields values
            o_regular_interval           := NULL;
            o_unit_meas_regular_interval := nvl(i_unit_meas_regular_interval, g_unit_measure_hour);
        
            -- process execution times
            -- clean predefined time schedules if daily executions field was edited by the user
            IF i_edit_field_name = g_edit_field_daily_executions
            THEN
                -- set fields values
                o_predef_time_sched := NULL;
                o_daily_executions  := i_daily_executions;
                l_orcplt_exec_times := NULL;
            
                -- if predefined time schedules were defined
            ELSIF (i_edit_field_name IS NULL OR i_edit_field_name = g_edit_field_predef_sched)
                  AND (i_predef_time_sched IS NOT NULL AND i_predef_time_sched.count > 0 AND
                  i_predef_time_sched(1) IS NOT NULL)
            THEN
                g_error := 'predefined time schedules';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- get predefined time schedule execution times
                IF NOT get_order_option_executions(i_lang                   => i_lang,
                                                   i_prof                   => i_prof,
                                                   i_order_option           => i_predef_time_sched(1), -- get first value (Flash only allows the user to select a single predefined time schedule)
                                                   o_order_option_exec_time => l_orcotmsi_exec_times,
                                                   o_error                  => o_error)
                THEN
                    g_error := 'error found while calling get_order_option_executions function';
                    RAISE e_user_exception;
                END IF;
            
                -- change execution times data structure
                SELECT t_rec_orcplt(NULL,
                                    i_order_recurr_plan,
                                    i_predef_time_sched(1), -- get first value (Flash only allows the user to select a single predefined time schedule)
                                    orcotmsi.id_order_recurr_option,
                                    exec_time,
                                    exec_time_offset,
                                    id_unit_meas_exec_time_offset)
                  BULK COLLECT
                  INTO l_orcplt_exec_times
                  FROM TABLE(CAST(l_orcotmsi_exec_times AS t_tbl_orcotmsi)) orcotmsi;
            
                -- process predefined time schedules ids
                SELECT DISTINCT exec_time_parents.column_value
                  BULK COLLECT
                  INTO o_predef_time_sched
                  FROM TABLE(i_exec_time_parent_option) exec_time_parents
                 WHERE exec_time_parents.column_value IS NOT NULL;
            
                -- set predefined time schedule field value
                o_predef_time_sched := i_predef_time_sched;
            
                -- set number of execution times
                o_daily_executions := l_orcplt_exec_times.count;
            
                -- process executions times defined by the user
            ELSE
                g_error := 'exact times definition';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- set fields values
                -- if any exact time was defined directly by the user, then remove predefined time schedule data
                IF instr(i_edit_field_name, g_edit_field_exact_time) != 0
                   OR i_edit_field_name IS NULL
                THEN
                    o_predef_time_sched := NULL;
                ELSE
                    o_predef_time_sched := i_predef_time_sched;
                END IF;
            
                o_daily_executions := nvl(i_daily_executions, 1);
            
                -- get executions times defined by the user
                FOR i IN 1 .. i_exec_time.count
                LOOP
                    l_orcplt_exec_times.extend;
                    l_exec_times_count := l_exec_times_count + 1;
                
                    -- it's not possible to have some execution time fields filled and others not
                    -- all fields must be filled or empty
                    IF i != 1
                       AND ((l_previous_exec_time IS NULL AND i_exec_time(i) IS NOT NULL) OR
                       (l_previous_exec_time IS NOT NULL AND i_exec_time(i) IS NULL))
                    THEN
                        l_flg_exec_times_ok := pk_alert_constant.g_no;
                    ELSE
                        l_previous_exec_time := i_exec_time(i);
                    END IF;
                
                    -- if any exact time was defined directly by the user, then remove predefined time schedule data
                    IF instr(i_edit_field_name, g_edit_field_exact_time) != 0
                       OR i_edit_field_name IS NULL
                       OR (i_predef_time_sched IS NOT NULL AND i_predef_time_sched.count > 0 AND
                           i_predef_time_sched(1) IS NULL)
                    THEN
                        g_error := '1 - i_exec_time' || (i) || ' = ' || i_exec_time(i) || 'i_exec_time_offset' || (i) ||
                                   ' = ' || i_exec_time_offset(i) || 'i_unit_meas_exec_time_offset' || (i) || ' = ' ||
                                   i_unit_meas_exec_time_offset(i);
                    
                        l_orcplt_exec_times(l_exec_times_count) := t_rec_orcplt(NULL,
                                                                                i_order_recurr_plan,
                                                                                NULL,
                                                                                NULL,
                                                                                decode_exec_time(i_lang,
                                                                                                 i_prof,
                                                                                                 i_exec_time(i),
                                                                                                 i_exec_time_offset(i),
                                                                                                 i_unit_meas_exec_time_offset(i)),
                                                                                i_exec_time_offset(i),
                                                                                i_unit_meas_exec_time_offset(i));
                    ELSE
                        g_error := '2 - i_exec_time' || (i) || ' = ' || i_exec_time(i) || 'i_exec_time_offset' || (i) ||
                                   ' = ' || i_exec_time_offset(i) || 'i_unit_meas_exec_time_offset' || (i) || ' = ' ||
                                   i_unit_meas_exec_time_offset(i);
                    
                        l_orcplt_exec_times(l_exec_times_count) := t_rec_orcplt(NULL,
                                                                                i_order_recurr_plan,
                                                                                i_exec_time_parent_option(i),
                                                                                i_exec_time_option(i),
                                                                                decode_exec_time(i_lang,
                                                                                                 i_prof,
                                                                                                 i_exec_time(i),
                                                                                                 i_exec_time_offset(i),
                                                                                                 i_unit_meas_exec_time_offset(i)),
                                                                                i_exec_time_offset(i),
                                                                                i_unit_meas_exec_time_offset(i));
                    END IF;
                END LOOP;
            END IF;
        
            -- get execution times cursor
            SELECT t_recurr_exec_times(id_order_recurr_plan,
                                       exec_time_parent_option,
                                       exec_time_option,
                                       exec_time,
                                       exec_time_desc)
              BULK COLLECT
              INTO o_exec_times
              FROM (SELECT i_order_recurr_plan id_order_recurr_plan,
                           exec_time_parent_option,
                           exec_time_option,
                           encode_exec_time(i_lang, i_prof, exec_time_aux) AS exec_time,
                           get_exec_time_desc(i_lang, i_prof, exec_time_aux) ||
                           nvl2(exec_time_option,
                                ' (' || get_order_recurr_option_desc(i_lang, i_prof, exec_time_option) || ')',
                                NULL) AS exec_time_desc
                      FROM (SELECT orcplt.id_order_recurr_option_parent AS exec_time_parent_option,
                                   orcplt.id_order_recurr_option_child AS exec_time_option,
                                   add_offset_to_tstz(orcplt.exec_time_offset,
                                                      get_timestamp_day_tstz(i_lang, i_prof, l_sysdate) + orcplt.exec_time,
                                                      orcplt.id_unit_meas_exec_time_offset) AS exec_time_aux,
                                   orcplt.exec_time_offset AS exec_time_offset,
                                   orcplt.id_unit_meas_exec_time_offset AS unit_meas_exec_time_offset
                              FROM TABLE(CAST(l_orcplt_exec_times AS t_tbl_orcplt)) orcplt)
                     ORDER BY exec_time);
        
            -- adjust end date according to exec times
            SELECT MAX(add_offset_to_tstz(orcplt.exec_time_offset,
                                          get_timestamp_day_tstz(i_lang, i_prof, i_end_date) + orcplt.exec_time,
                                          orcplt.id_unit_meas_exec_time_offset)) AS max_exec_time
              INTO l_end_date
              FROM TABLE(CAST(l_orcplt_exec_times AS t_tbl_orcplt)) orcplt;
        
            -- adjust start date according to exec times
            SELECT MIN(min_exec_time)
              INTO l_start_date
              FROM (SELECT add_offset_to_tstz(orcplt.exec_time_offset,
                                              get_timestamp_day_tstz(i_lang, i_prof, i_start_date) + orcplt.exec_time,
                                              orcplt.id_unit_meas_exec_time_offset) AS min_exec_time
                    
                      FROM TABLE(CAST(l_orcplt_exec_times AS t_tbl_orcplt)) orcplt)
             WHERE min_exec_time IS NULL
                OR min_exec_time >= l_sysdate_trunc;
        
            -- if there's no exec times to perform today
            IF l_start_date IS NULL
            THEN
                -- get all start date possibilities regarding all the exec times
                SELECT MIN(add_offset_to_tstz(orcplt.exec_time_offset,
                                              get_timestamp_day_tstz(i_lang, i_prof, i_start_date) + orcplt.exec_time,
                                              orcplt.id_unit_meas_exec_time_offset)) AS min_exec_time
                  INTO l_start_date
                  FROM TABLE(CAST(l_orcplt_exec_times AS t_tbl_orcplt)) orcplt;
            
                IF l_start_date IS NOT NULL
                THEN
                    -- shift one day forward if all exec times are in the past considering the current start date
                    l_start_date := l_start_date + 1;
                    l_end_date   := l_end_date + 1;
                ELSE
                    l_start_date := i_start_date;
                    l_end_date   := i_end_date;
                END IF;
            END IF;
        
            -- set fields enabled/disabled
            o_flg_regular_interval_edit  := pk_alert_constant.g_yes;
            o_flg_daily_executions_edit  := pk_alert_constant.g_yes;
            o_flg_predef_time_sched_edit := pk_alert_constant.g_yes;
            o_flg_exec_time_edit         := pk_alert_constant.g_yes;
        
        ELSE
        
            -- set fields values
            o_regular_interval           := NULL;
            o_unit_meas_regular_interval := nvl(i_unit_meas_regular_interval, g_unit_measure_hour);
            o_daily_executions           := 1;
            o_predef_time_sched          := NULL;
        
            -- set fields enabled/disabled
            o_flg_regular_interval_edit  := pk_alert_constant.g_yes;
            o_flg_daily_executions_edit  := pk_alert_constant.g_yes;
            o_flg_predef_time_sched_edit := pk_alert_constant.g_yes;
            o_flg_exec_time_edit         := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'check recurrence pattern parameters';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- disable all reccurence pattern fields if there is no recurrence pattern defined
        IF i_flg_recurr_pattern = g_flg_recurr_pattern_none
        THEN
        
            -- set fields values
            o_flg_recurr_pattern     := g_flg_recurr_pattern_none;
            o_repeat_every           := NULL;
            o_unit_meas_repeat_every := NULL;
            o_flg_repeat_by          := NULL;
            IF l_start_date IS NOT NULL
            THEN
                o_start_date := trunc_timestamp_to_minutes(i_lang, i_prof, l_start_date);
            ELSE
                o_start_date := current_timestamp;
            END IF;
            o_flg_end_by := i_flg_end_by;
            o_month      := NULL;
        
            -- set fields enabled/disabled
            o_flg_repeat_every_edit := pk_alert_constant.g_no;
            o_flg_repeat_by_edit    := pk_alert_constant.g_no;
            o_flg_start_date_edit   := pk_alert_constant.g_yes;
            o_flg_end_by_edit       := pk_alert_constant.g_yes;
            o_flg_month_edit        := pk_alert_constant.g_no;
        
            -- process daily order recurrence pattern
        ELSIF i_flg_recurr_pattern IS NULL
        THEN
            o_regular_interval       := NULL;
            o_unit_meas_repeat_every := g_unit_measure_day;
            o_flg_recurr_pattern     := g_flg_recurr_pattern_none;
            o_repeat_every           := NULL;
            --o_unit_meas_repeat_every := NULL;
        
            o_flg_repeat_by := NULL;
        
            IF l_start_date IS NULL
            THEN
                o_start_date := NULL;
            ELSE
                o_start_date := trunc_timestamp_to_minutes(i_lang, i_prof, l_start_date);
            END IF;
        
            o_flg_end_by := i_flg_end_by;
            o_month      := NULL;
        
            -- set fields enabled/disabled
            o_flg_repeat_every_edit := pk_alert_constant.g_no;
            o_flg_repeat_by_edit    := pk_alert_constant.g_no;
        
            IF l_start_date IS NULL
            THEN
                o_flg_start_date_edit := pk_alert_constant.g_no;
            ELSE
                o_flg_start_date_edit := pk_alert_constant.g_yes;
            END IF;
        
            o_flg_end_by_edit := pk_alert_constant.g_yes;
            o_flg_month_edit  := pk_alert_constant.g_no;
        
        ELSIF (i_flg_recurr_pattern = g_flg_recurr_pattern_daily AND
              (i_edit_field_name != g_edit_field_regular_intervals OR i_edit_field_name IS NULL))
        THEN
        
            -- set fields values
            o_regular_interval       := NULL;
            o_flg_recurr_pattern     := g_flg_recurr_pattern_daily;
            o_repeat_every           := nvl(i_repeat_every, 1);
            o_unit_meas_repeat_every := g_unit_measure_day;
        
            o_flg_repeat_by := NULL;
        
            IF l_start_date IS NULL
            THEN
                o_start_date := NULL;
            ELSE
                o_start_date := trunc_timestamp_to_minutes(i_lang, i_prof, l_start_date);
            END IF;
        
            o_flg_end_by := i_flg_end_by;
            o_month      := NULL;
        
            -- set fields enabled/disabled
            o_flg_repeat_every_edit := pk_alert_constant.g_yes;
            o_flg_repeat_by_edit    := pk_alert_constant.g_no;
        
            IF l_start_date IS NULL
            THEN
                o_flg_start_date_edit := pk_alert_constant.g_no;
            ELSE
                o_flg_start_date_edit := pk_alert_constant.g_yes;
            END IF;
        
            o_flg_end_by_edit := pk_alert_constant.g_yes;
            o_flg_month_edit  := pk_alert_constant.g_no;
        
            -- process weekly order recurrence pattern
        ELSIF i_flg_recurr_pattern = g_flg_recurr_pattern_weekly
              AND (i_edit_field_name != g_edit_field_regular_intervals OR i_edit_field_name IS NULL)
        THEN
        
            -- set fields values
            o_flg_recurr_pattern     := i_flg_recurr_pattern;
            o_repeat_every           := nvl(i_repeat_every, 1);
            o_unit_meas_repeat_every := g_unit_measure_week;
            o_flg_repeat_by          := i_flg_repeat_by;
            o_start_date             := trunc_timestamp_to_minutes(i_lang, i_prof, l_start_date);
            o_flg_end_by             := i_flg_end_by;
            o_month                  := NULL;
        
            -- set fields enabled/disabled
            o_flg_repeat_every_edit := pk_alert_constant.g_yes;
            o_flg_repeat_by_edit    := pk_alert_constant.g_no;
            o_flg_start_date_edit   := pk_alert_constant.g_yes;
            o_flg_end_by_edit       := pk_alert_constant.g_yes;
            o_flg_month_edit        := pk_alert_constant.g_no;
        
            -- process monthly order recurrence pattern
        ELSIF i_flg_recurr_pattern = g_flg_recurr_pattern_monthly
              AND (i_edit_field_name != g_edit_field_regular_intervals OR i_edit_field_name IS NULL)
        THEN
        
            -- set fields values
            o_flg_recurr_pattern     := i_flg_recurr_pattern;
            o_repeat_every           := nvl(i_repeat_every, 1);
            o_unit_meas_repeat_every := g_unit_measure_month;
            o_flg_repeat_by          := i_flg_repeat_by;
            o_start_date             := trunc_timestamp_to_minutes(i_lang, i_prof, l_start_date);
            o_flg_end_by             := i_flg_end_by;
            o_month                  := NULL;
        
            -- set fields enabled/disabled
            o_flg_repeat_every_edit := pk_alert_constant.g_yes;
            o_flg_repeat_by_edit    := pk_alert_constant.g_yes;
            o_flg_start_date_edit   := pk_alert_constant.g_yes;
            o_flg_end_by_edit       := pk_alert_constant.g_yes;
            o_flg_month_edit        := pk_alert_constant.g_no;
        
            -- process yearly order recurrence pattern
        ELSIF i_flg_recurr_pattern = g_flg_recurr_pattern_yearly
              AND (i_edit_field_name != g_edit_field_regular_intervals OR i_edit_field_name IS NULL)
        THEN
        
            -- set fields values
            o_flg_recurr_pattern     := i_flg_recurr_pattern;
            o_repeat_every           := nvl(i_repeat_every, 1);
            o_unit_meas_repeat_every := g_unit_measure_year;
            o_flg_repeat_by          := i_flg_repeat_by;
            o_start_date             := trunc_timestamp_to_minutes(i_lang, i_prof, l_start_date);
            o_flg_end_by             := i_flg_end_by;
            o_month                  := i_month;
        
            -- set fields enabled/disabled
            o_flg_repeat_every_edit := pk_alert_constant.g_yes;
            o_flg_repeat_by_edit    := pk_alert_constant.g_yes;
            o_flg_start_date_edit   := pk_alert_constant.g_yes;
            o_flg_end_by_edit       := pk_alert_constant.g_yes;
            o_flg_month_edit        := pk_alert_constant.g_yes;
        
        END IF;
    
        -- process "week day", "week" and "month day" fields according to "repeat by" field value
        IF o_flg_repeat_by = g_flg_repeat_by_week_days
        THEN
        
            -- set fields values
            o_flg_week_day := i_flg_week_day;
            o_flg_week     := i_flg_week;
            o_month_day    := NULL;
        
            -- set fields enabled/disabled
            o_flg_week_day_edit  := pk_alert_constant.g_yes;
            o_flg_week_edit      := pk_alert_constant.g_yes;
            o_flg_month_day_edit := pk_alert_constant.g_no;
        
        ELSIF o_flg_repeat_by = g_flg_repeat_by_month_days
        THEN
        
            -- set fields values
            o_flg_week_day := NULL;
            o_flg_week     := NULL;
            o_month_day    := i_month_day;
        
            -- set fields enabled/disabled
            o_flg_week_day_edit  := pk_alert_constant.g_no;
            o_flg_week_edit      := pk_alert_constant.g_no;
            o_flg_month_day_edit := pk_alert_constant.g_yes;
        
        ELSE
            -- set fields values
            o_flg_week_day := NULL;
            o_flg_week     := NULL;
            o_month_day    := NULL;
        
            -- set fields enabled/disabled
            o_flg_week_day_edit  := pk_alert_constant.g_no;
            o_flg_week_edit      := pk_alert_constant.g_no;
            o_flg_month_day_edit := pk_alert_constant.g_no;
        END IF;
    
        -- process "end by" fields
        IF o_flg_end_by IS NULL
           AND i_flg_context != g_context_settings
        THEN
            -- set fields values
            o_flg_end_by         := g_flg_end_by_date;
            o_occurrences        := NULL;
            o_duration           := NULL; -- put here order recurrence config
            o_unit_meas_duration := NULL;
        
            -- calculate end date based on order recurrence active window configuration
            IF NOT get_order_recurr_cfg(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_order_recurr_area => l_id_order_recurr_area,
                                        i_interval_name     => g_cfg_name_active_window,
                                        i_id_market         => l_id_market,
                                        o_interval_value    => l_interval,
                                        o_error             => o_error)
            THEN
                RAISE e_user_exception;
            END IF;
        
            o_end_date := o_start_date + l_interval;
        
            -- set fields enabled/disabled
            o_flg_end_after_edit := pk_alert_constant.g_yes;
        ELSIF o_flg_end_by = g_flg_end_by_no_end
        THEN
            -- set fields values
            o_flg_end_by         := g_flg_end_by_no_end;
            o_occurrences        := NULL;
            o_duration           := NULL;
            o_unit_meas_duration := NULL;
            o_end_date           := NULL;
        
            -- set fields enabled/disabled
            o_flg_end_after_edit := pk_alert_constant.g_no;
        ELSIF o_flg_end_by = g_flg_end_by_date
        THEN
            -- set fields values
            o_flg_end_by         := i_flg_end_by;
            o_occurrences        := NULL;
            o_duration           := NULL;
            o_unit_meas_duration := NULL;
        
            IF (i_end_date IS NULL)
            THEN
                -- calculate end date based on order recurrence active window configuration
                IF NOT get_order_recurr_cfg(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_order_recurr_area => l_id_order_recurr_area,
                                            i_interval_name     => g_cfg_name_active_window,
                                            i_id_market         => l_id_market,
                                            o_interval_value    => l_interval,
                                            o_error             => o_error)
                THEN
                    RAISE e_user_exception;
                END IF;
            
                o_end_date := o_start_date + l_interval;
            ELSE
                o_end_date := l_end_date;
            END IF;
        
            -- set fields enabled/disabled
            o_flg_end_after_edit := pk_alert_constant.g_yes;
        ELSIF o_flg_end_by = g_flg_end_by_occurrences
        THEN
            -- set fields values
            o_flg_end_by         := i_flg_end_by;
            o_occurrences        := i_occurrences;
            o_duration           := NULL;
            o_unit_meas_duration := NULL;
            o_end_date           := NULL;
        
            -- set fields enabled/disabled
            o_flg_end_after_edit := pk_alert_constant.g_yes;
        ELSIF o_flg_end_by = g_flg_end_by_duration
        THEN
            -- set fields values
            o_flg_end_by         := i_flg_end_by;
            o_occurrences        := NULL;
            o_duration           := i_duration;
            o_unit_meas_duration := nvl(i_unit_meas_duration, g_unit_measure_day);
            o_end_date           := NULL;
        
            -- set fields enabled/disabled
            o_flg_end_after_edit := pk_alert_constant.g_yes;
        END IF;
    
        -- TODO: force fields inactivation (waiting for 2nd phase order recurrence developments)
        o_flg_repeat_by_edit := pk_alert_constant.g_no; -- TODO
        o_flg_week_day_edit  := pk_alert_constant.g_no; -- TODO
        o_flg_week_edit      := pk_alert_constant.g_no; -- TODO
        o_flg_month_day_edit := pk_alert_constant.g_no; -- TODO
        o_flg_month_edit     := pk_alert_constant.g_no; -- TODO
    
        -- when context is personal settings, dates are managed in a different way (than patient context)
        IF i_flg_context = g_context_settings
        THEN
        
            -- start date is null, only set when we order the task (patient context)
            o_start_date          := NULL;
            o_flg_start_date_edit := pk_alert_constant.g_no;
        
            -- end_after is not editable if settings context if flg_end_by require a date: only set when we order the task (patient context)
            IF o_flg_end_by = g_flg_end_by_date
            THEN
                o_flg_end_after_edit := pk_alert_constant.g_no;
                o_end_date           := NULL;
            END IF;
        END IF;
    
        -- check if ok button must be enabled or not
        IF (o_flg_regular_interval_edit = pk_alert_constant.g_yes AND
           (o_regular_interval IS NULL OR o_unit_meas_regular_interval IS NULL) AND
           (o_flg_daily_executions_edit = pk_alert_constant.g_yes AND o_daily_executions IS NULL))
          --
           OR l_flg_exec_times_ok = pk_alert_constant.g_no
          --
           OR (o_flg_repeat_every_edit = pk_alert_constant.g_yes AND o_repeat_every IS NULL)
          --
           OR (o_flg_repeat_by_edit = pk_alert_constant.g_yes AND o_flg_repeat_by IS NULL)
          --
           OR (o_start_date IS NULL AND i_flg_context = g_context_patient)
          --
           OR (o_flg_end_by_edit = pk_alert_constant.g_yes AND o_flg_end_by IS NULL)
          --
           OR (o_flg_end_after_edit = pk_alert_constant.g_yes AND
           ((o_flg_end_by = g_flg_end_by_date AND o_end_date IS NULL AND i_flg_context = g_context_patient) OR
           (o_flg_end_by = g_flg_end_by_occurrences AND o_occurrences IS NULL) OR
           (o_flg_end_by = g_flg_end_by_duration AND (o_duration IS NULL OR o_unit_meas_duration IS NULL))))
          --
           OR (o_flg_repeat_by_edit = pk_alert_constant.g_yes AND o_flg_repeat_by IS NOT NULL AND
           o_flg_repeat_by = g_flg_repeat_by_week_days AND
           ((o_flg_week_day_edit = pk_alert_constant.g_yes AND o_flg_week_day IS NULL) OR
           (o_flg_week_edit = pk_alert_constant.g_yes AND o_flg_week IS NULL)))
          --
           OR (o_flg_repeat_by_edit = pk_alert_constant.g_no AND o_flg_repeat_by IS NOT NULL AND
           o_flg_repeat_by = g_flg_repeat_by_month_days AND
           ((o_flg_month_day_edit = pk_alert_constant.g_yes AND o_month_day IS NULL) OR
           (o_flg_month_edit = pk_alert_constant.g_yes AND o_month IS NULL)))
        THEN
            o_flg_ok_avail := pk_alert_constant.g_no;
        ELSE
            o_flg_ok_avail := pk_alert_constant.g_yes;
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
                                              'CHECK_OTHER_RECURR_OPTION',
                                              o_error);
            RETURN FALSE;
    END check_other_recurr_option;

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
    ) RETURN VARCHAR2 IS
        l_desc VARCHAR2(200 CHAR);
    BEGIN
        -- build description based in i_flg_end_by
        CASE
        -- end by date 'D'
            WHEN i_flg_end_by = g_flg_end_by_date THEN
                IF i_end_date IS NOT NULL
                THEN
                    l_desc := pk_date_utils.date_char_tsz(i_lang, i_end_date, i_prof.institution, i_prof.software);
                ELSE
                    l_desc := NULL;
                END IF;
                -- end by duration 'L'
            WHEN i_flg_end_by = g_flg_end_by_duration THEN
                IF i_duration IS NOT NULL
                THEN
                    l_desc := i_duration || ' ' ||
                              pk_unit_measure.get_unit_measure_description(i_lang, i_prof, i_unit_meas_duration);
                ELSE
                    l_desc := NULL;
                END IF;
                -- end by number of executions or occurrences 'N'
            WHEN i_flg_end_by = g_flg_end_by_occurrences THEN
                IF i_occurrences IS NOT NULL
                THEN
                    l_desc := i_occurrences || ' ' || pk_message.get_message(i_lang, 'ORDER_RECURRENCE_M001');
                ELSE
                    l_desc := NULL;
                END IF;
                -- no end date or no option defined NULL or 'W'
            ELSE
                l_desc := NULL;
        END CASE;
        -- return processed description
        RETURN l_desc;
    END get_order_rec_end_after_desc;

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
    ) RETURN BOOLEAN IS
    
        CURSOR c_control_cfg
        (
            x_id_order_recurr_area IN order_recurr_control_cfg.id_order_recurr_area%TYPE,
            x_interval_name        IN order_recurr_control_cfg.interval_name%TYPE,
            x_id_market            IN order_recurr_control_cfg.id_market%TYPE
        ) IS
            SELECT interval_value
              FROM order_recurr_control_cfg c
             WHERE c.id_order_recurr_area = x_id_order_recurr_area
               AND c.interval_name = x_interval_name
               AND c.id_market IN (x_id_market, 0)
               AND c.id_institution IN (i_prof.institution, 0)
             ORDER BY id_market DESC, id_institution DESC;
    
        l_id_market order_recurr_control_cfg.id_market%TYPE;
    BEGIN
    
        g_error := 'Init get_order_recurr_cfg / i_order_recurr_area=' || i_order_recurr_area || ' i_interval_name=' ||
                   i_interval_name;
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get id_market value if not set
        l_id_market := nvl(i_id_market, pk_utils.get_institution_market(i_lang, i_prof.institution));
    
        OPEN c_control_cfg(i_order_recurr_area, i_interval_name, l_id_market);
        FETCH c_control_cfg
            INTO o_interval_value;
        CLOSE c_control_cfg;
    
        -- if no configuration for active window is returned, then assume default value
        o_interval_value := nvl(o_interval_value, g_active_window_def);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDER_RECURR_CFG',
                                              o_error);
            RETURN FALSE;
    END get_order_recurr_cfg;

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
    
        -- order recurr plans to be processed
        CURSOR c_control IS
            SELECT c.id_order_recurr_plan,
                   c.dt_last_processed,
                   c.id_order_recurr_area,
                   c.last_exec_order,
                   c.dt_last_exec,
                   p.flg_recurr_pattern,
                   p.repeat_every,
                   c.flg_status
              FROM order_recurr_control c
             INNER JOIN order_recurr_plan p
                ON c.id_order_recurr_plan = p.id_order_recurr_plan
             WHERE c.id_order_recurr_plan = i_order_recurr_plan;
    
        l_control      c_control%ROWTYPE;
        l_interval_cfg order_recurr_control_cfg.interval_value%TYPE;
    
        l_dt_start TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_order_plan_tab       t_tbl_order_recurr_plan;
        l_order_plan_execution t_tbl_order_recurr_plan;
        l_last_exec_reached    VARCHAR2(1 CHAR);
    
        l_last_exec_order order_recurr_control.last_exec_order%TYPE;
        l_dt_last_exec    order_recurr_control.dt_last_exec%TYPE;
    
        l_exec_to_process t_tbl_order_recurr_plan_sts := t_tbl_order_recurr_plan_sts();
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        -- if there are active executions, does not create an extra execution
        IF i_active_executions > 0
        THEN
            g_error := 'there are no other active executions (i_active_executions=0)';
            pk_alertlog.log_debug(g_error);
            RETURN TRUE;
        END IF;
    
        -- get order recurrence control record of this order recurrence plan
        OPEN c_control;
        FETCH c_control
            INTO l_control;
        CLOSE c_control;
    
        -- the order recurrence plan was already finished or outdated (no more executions need to be created)
        IF l_control.flg_status != g_flg_status_control_active
        THEN
            g_error := 'the order plan [' || i_order_recurr_plan || '] is not active (nothing to be done here)';
            pk_alertlog.log_debug(g_error);
            RETURN TRUE;
        END IF;
    
        -- get default interval to add to the end date processing as a tolerance value
        IF NOT get_order_recurr_cfg(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_order_recurr_area => l_control.id_order_recurr_area,
                                    i_interval_name     => g_cfg_name_active_window,
                                    o_interval_value    => l_interval_cfg,
                                    o_error             => o_error)
        THEN
            g_error := 'error found while calling pk_order_recurrence_core.get_order_recurr_cfg function';
            RAISE l_exception;
        END IF;
    
        -- get start date
        l_dt_start := l_control.dt_last_processed;
    
        -- get end date according to recurrence pattern
        IF l_control.flg_recurr_pattern = g_flg_recurr_pattern_none
        THEN
            l_dt_end := l_dt_start + numtodsinterval(1, 'DAY');
        ELSIF l_control.flg_recurr_pattern = g_flg_recurr_pattern_daily
        THEN
            l_dt_end := l_dt_start + l_interval_cfg + numtodsinterval(l_control.repeat_every, 'DAY');
        ELSIF l_control.flg_recurr_pattern = g_flg_recurr_pattern_weekly
        THEN
            l_dt_end := l_dt_start + l_interval_cfg + numtodsinterval(7 * l_control.repeat_every, 'DAY');
        ELSIF l_control.flg_recurr_pattern = g_flg_recurr_pattern_monthly
        THEN
            l_dt_end := l_dt_start + l_interval_cfg + numtoyminterval(l_control.repeat_every, 'MONTH');
        ELSIF l_control.flg_recurr_pattern = g_flg_recurr_pattern_yearly
        THEN
            l_dt_end := l_dt_start + l_interval_cfg + numtoyminterval(l_control.repeat_every, 'YEAR');
        ELSE
            l_dt_end := l_dt_start + l_interval_cfg;
        END IF;
    
        g_error := 'check l_dt_start and l_dt_end';
        pk_alertlog.log_debug(g_error);
    
        IF l_dt_start >= l_dt_end
        THEN
            -- nothing to be processed
            RETURN TRUE;
        END IF;
    
        -- getting recurrence plan info
        g_error := 'Get planned recurrence events / i_order_recurr_plan=' || i_order_recurr_plan ||
                   ' i_proc_from_exec_nr=' || l_control.last_exec_order;
        pk_alertlog.log_debug(g_error);
    
        IF NOT get_order_recurr_plan(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_order_plan        => i_order_recurr_plan,
                                     i_plan_start_date   => l_dt_start,
                                     i_plan_end_date     => l_dt_end,
                                     i_proc_from_day     => l_control.dt_last_exec,
                                     i_proc_from_exec_nr => l_control.last_exec_order,
                                     o_order_plan        => l_order_plan_tab,
                                     o_last_exec_reached => l_last_exec_reached,
                                     o_error             => o_error)
        THEN
            g_error := 'error found while calling get_order_recurr_plan function / id_order_recurr_plan=' ||
                       i_order_recurr_plan;
            RAISE l_exception;
        END IF;
    
        g_error := 'l_order_plan_tab.COUNT=' || l_order_plan_tab.count;
        pk_alertlog.log_debug(g_error);
    
        -- process executions of all areas
        IF l_order_plan_tab.count > 0
        THEN
        
            g_error := 'ID_ORDER_RECURR_AREA=' || l_control.id_order_recurr_area;
            pk_alertlog.log_debug(g_error);
        
            -- initialize collection
            l_exec_to_process := NULL;
        
            -- get first execution only
            -- l_order_plan_execution := t_tbl_order_recurr_plan(l_order_plan_tab(1));
        
            CASE
                WHEN l_control.id_order_recurr_area = g_area_lab_test THEN
                
                    -- LAB TEST
                    g_error := 'call pk_lab_tests_api_db.create_lab_test_recurrence';
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_lab_tests_api_db.create_lab_test_recurrence(i_lang     => i_lang,
                                                                          i_prof     => i_prof,
                                                                          i_exec_tab => l_order_plan_tab,
                                                                          
                                                                          o_exec_to_process => l_exec_to_process,
                                                                          o_error           => o_error)
                    THEN
                        g_error := 'error found while calling pk_lab_tests_api_db.create_lab_test_recurrence function / id_order_recurr_plan=' ||
                                   i_order_recurr_plan;
                        RAISE l_exception;
                    END IF;
                
                WHEN l_control.id_order_recurr_area IN (g_area_image_exam, g_area_other_exam) THEN
                
                    -- IMAGE EXAM or OTHER EXAM
                    g_error := 'call pk_exams_api_db.create_exam_recurrence';
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_exams_api_db.create_exam_recurrence(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_exec_tab        => l_order_plan_tab,
                                                                  o_exec_to_process => l_exec_to_process,
                                                                  o_error           => o_error)
                    THEN
                        g_error := 'error found while calling pk_exams_api_db.create_exam_recurrence function / id_order_recurr_plan=' ||
                                   i_order_recurr_plan;
                        RAISE l_exception;
                    END IF;
                
                WHEN l_control.id_order_recurr_area = g_area_pat_education THEN
                
                    -- PATIENT EDUCATION
                    g_error := 'call pk_patient_education_api_db.create_executions';
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_patient_education_api_db.create_executions(i_lang            => i_lang,
                                                                         i_prof            => i_prof,
                                                                         i_exec_tab        => l_order_plan_tab,
                                                                         o_exec_to_process => l_exec_to_process,
                                                                         o_error           => o_error)
                    THEN
                        g_error := 'error found while calling pk_patient_education_api_db.create_executions function / id_order_recurr_plan=' ||
                                   i_order_recurr_plan;
                        RAISE l_exception;
                    END IF;
                
                WHEN l_control.id_order_recurr_area = g_area_icnp THEN
                
                    -- ICNP
                    g_error := 'call pk_icnp_fo_api_db.create_executions';
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_icnp_fo_api_db.create_executions(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_exec_tab        => l_order_plan_tab,
                                                               i_sysdate_tstz    => l_sysdate,
                                                               o_exec_to_process => l_exec_to_process,
                                                               o_error           => o_error)
                    THEN
                        g_error := 'error found while calling pk_icnp_fo_api_db.create_executions function / id_order_recurr_plan=' ||
                                   i_order_recurr_plan;
                        RAISE l_exception;
                    END IF;
                
                WHEN l_control.id_order_recurr_area = g_area_nnn_noc_outcome THEN
                    -- Nursing Care Plan (NANDA/NIC/NOC): NOC Outcome
                    g_error := 'call pk_nnn_api_db.create_outcome_recurrence';
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_nnn_api_db.create_outcome_recurrence(i_lang            => i_lang,
                                                                   i_prof            => i_prof,
                                                                   i_exec_tab        => l_order_plan_tab,
                                                                   i_timestamp       => l_sysdate,
                                                                   o_exec_to_process => l_exec_to_process,
                                                                   o_error           => o_error)
                    THEN
                        g_error := 'error found while calling pk_nnn_api_db.create_outcome_recurrence function / id_order_recurr_plan=' ||
                                   i_order_recurr_plan;
                        RAISE l_exception;
                    END IF;
                
                WHEN l_control.id_order_recurr_area = g_area_nnn_noc_indicator THEN
                    -- Nursing Care Plan (NANDA/NIC/NOC): NOC Indicator
                    g_error := 'call pk_nnn_api_db.create_indicator_recurrence';
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_nnn_api_db.create_indicator_recurrence(i_lang            => i_lang,
                                                                     i_prof            => i_prof,
                                                                     i_exec_tab        => l_order_plan_tab,
                                                                     i_timestamp       => l_sysdate,
                                                                     o_exec_to_process => l_exec_to_process,
                                                                     o_error           => o_error)
                    THEN
                        g_error := 'error found while calling pk_nnn_api_db.create_indicator_recurrence function / id_order_recurr_plan=' ||
                                   i_order_recurr_plan;
                        RAISE l_exception;
                    END IF;
                
                WHEN l_control.id_order_recurr_area = g_area_nnn_nic_activity THEN
                    -- Nursing Care Plan (NANDA/NIC/NOC): NIC Activity
                    g_error := 'call pk_nnn_api_db.create_activity_recurrence';
                    pk_alertlog.log_debug(g_error);
                
                    IF NOT pk_nnn_api_db.create_activity_recurrence(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_exec_tab        => l_order_plan_tab,
                                                                    i_timestamp       => l_sysdate,
                                                                    o_exec_to_process => l_exec_to_process,
                                                                    o_error           => o_error)
                    THEN
                        g_error := 'error found while calling pk_nnn_api_db.create_activity_recurrence function / id_order_recurr_plan=' ||
                                   i_order_recurr_plan;
                        RAISE l_exception;
                    END IF;
                ELSE
                
                    -- area ID not found
                    g_error := 'order recurrence area ID not found: ' || l_control.id_order_recurr_area;
                    RETURN FALSE;
            END CASE;
        
            g_error := 'l_exec_to_process.COUNT=' || l_exec_to_process.count;
            pk_alertlog.log_debug(g_error);
        
            -- updates control table
            FOR i IN 1 .. l_exec_to_process.count
            LOOP
                -- for each plan
                g_error := 'last execution number and dates';
                pk_alertlog.log_debug(g_error);
            
                l_last_exec_order := l_order_plan_tab(l_order_plan_tab.count).exec_number;
                l_dt_last_exec    := l_order_plan_tab(l_order_plan_tab.count).exec_timestamp;
            
                g_error := 'UPDATE order_recurr_control / id_order_recurr_plan=' || l_exec_to_process(i).id_order_recurrence_plan ||
                           ' flg_Status=' || l_exec_to_process(i).flg_status || ' l_last_exec_reached=' ||
                           l_last_exec_reached || ' last_exec_order=' || l_last_exec_order;
                pk_alertlog.log_debug(g_error);
            
                UPDATE order_recurr_control c
                   SET c.flg_status        = decode(l_last_exec_reached,
                                                    pk_alert_constant.get_yes,
                                                    g_flg_status_control_finished,
                                                    decode(l_exec_to_process(i).flg_status,
                                                           pk_alert_constant.get_no,
                                                           g_flg_status_control_outdated,
                                                           c.flg_status)),
                       c.dt_last_processed = l_dt_end,
                       c.last_exec_order   = l_last_exec_order,
                       c.dt_last_exec      = l_dt_last_exec
                 WHERE c.id_order_recurr_plan = l_exec_to_process(i).id_order_recurrence_plan;
            
            END LOOP;
        
        ELSE
        
            -- updates control table
            g_error := 'UPDATE order_recurr_control / id_order_recurr_plan=' || i_order_recurr_plan ||
                       ' l_last_exec_reached=' || l_last_exec_reached;
            pk_alertlog.log_debug(g_error);
        
            UPDATE order_recurr_control c
               SET c.flg_status        = decode(l_last_exec_reached,
                                                pk_alert_constant.get_yes,
                                                g_flg_status_control_finished,
                                                c.flg_status),
                   c.dt_last_processed = l_dt_end
             WHERE c.id_order_recurr_plan = i_order_recurr_plan;
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
    * Maintenance of order recurrence plans
    * Called by job J_RECURR_CONTROL
    *
    * @author                                      Ana Monteiro
    * @since                                       06-MAY-2011
    ********************************************************************************************/
    PROCEDURE set_order_recurr_control IS
    
        -- every institution where hour=0
        CURSOR c_inst IS
            SELECT i.id_institution, tr.timezone_region
              FROM institution i
              JOIN timezone_region tr
                ON tr.id_timezone_region = i.id_timezone_region
             WHERE to_char(current_timestamp at TIME ZONE tr.timezone_region, 'HH24') = '00';
    
        l_id_inst_tab  table_number;
        l_timezone_tab table_varchar;
    
        -- order recurr plans to be processed
        CURSOR c_control(x_institution_tab IN table_number) IS
            SELECT /*+opt_estimate(table t rows=1)*/
             c.id_order_recurr_plan,
             c.dt_last_processed,
             c.id_order_recurr_area,
             c.last_exec_order,
             c.dt_last_exec,
             p.id_institution
              FROM order_recurr_plan p
              JOIN order_recurr_control c
                ON p.id_order_recurr_plan = c.id_order_recurr_plan
              JOIN TABLE(x_institution_tab) t
                ON t.column_value = p.id_institution
             WHERE c.flg_status = g_flg_status_control_active
               AND c.id_order_recurr_area NOT IN (g_area_adv_dir_dnar, g_area_procedure)
             ORDER BY c.id_order_recurr_area, p.id_institution;
    
        TYPE t_control IS TABLE OF c_control%ROWTYPE INDEX BY PLS_INTEGER;
        l_control_tab t_control;
    
        l_limit CONSTANT PLS_INTEGER := 2000;
    
        l_error            t_error_out;
        l_prof             profissional;
        l_lang             language.id_language%TYPE;
        l_prev_institution institution.id_institution%TYPE;
        l_prev_area        order_recurr_area.id_order_recurr_area%TYPE;
    
        l_interval order_recurr_control_cfg.interval_value%TYPE;
        l_dt_start TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_order_plan_tab    t_tbl_order_recurr_plan;
        l_last_exec_reached VARCHAR2(1 CHAR);
    
        l_last_exec_order order_recurr_control.last_exec_order%TYPE;
        l_dt_last_exec    order_recurr_control.dt_last_exec%TYPE;
    
        l_undo_changes    PLS_INTEGER;
        l_exec_to_process t_tbl_order_recurr_plan_sts := t_tbl_order_recurr_plan_sts();
    
        l_analysis            analysis_req_det.id_analysis%TYPE;
        l_sample_type         analysis_req_det.id_sample_type%TYPE;
        l_room                analysis_req_det.id_room%TYPE;
        l_flg_col_inst        analysis_req_det.flg_col_inst%TYPE;
        l_flg_time            analysis_req.flg_time%TYPE;
        l_id_exec_institution analysis_req.id_exec_institution%TYPE;
        l_flg_priority        analysis_req.flg_priority%TYPE;
        l_flg_prn             analysis_req_det.flg_prn%TYPE;
        l_institution         episode.id_institution%TYPE;
        l_professional        epis_info.id_professional%TYPE;
        l_software            epis_info.id_software%TYPE;
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        PROCEDURE print_exec(x_order_plan_tab IN t_tbl_order_recurr_plan) IS
        BEGIN
            FOR i IN 1 .. x_order_plan_tab.count
            LOOP
                pk_alertlog.log_debug('ID_PLAN=' || x_order_plan_tab(i).id_order_recurrence_plan || ' NR=' || x_order_plan_tab(i).exec_number ||
                                      ' DT=' || x_order_plan_tab(i).exec_timestamp);
            END LOOP;
        END print_exec;
    
        -- process error found while processing plan
        PROCEDURE process_plan_error(in_order_plan IN order_recurr_plan.id_order_recurr_plan%TYPE) IS
        
            PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
        
            -- update order recurrence plan status with error state
            UPDATE order_recurr_control orc
               SET orc.flg_status = g_flg_status_control_error
             WHERE orc.id_order_recurr_plan = in_order_plan;
        
            IF (SQL%ROWCOUNT = 1)
            THEN
                COMMIT;
            ELSE
                pk_utils.undo_changes;
            END IF;
        
        END process_plan_error;
    
    BEGIN
        g_error := 'Init set_order_recurr_control';
        l_prof  := profissional(NULL, 0, 0);
    
        l_undo_changes := 0;
    
        -------
        -- Getting all institutions where hour=00
        OPEN c_inst;
        FETCH c_inst BULK COLLECT
            INTO l_id_inst_tab, l_timezone_tab;
        CLOSE c_inst;
    
        IF l_id_inst_tab.count > 0
        THEN
        
            -------
            -- Getting order recurr plans to be processed
            g_error := 'OPEN c_control';
            OPEN c_control(l_id_inst_tab);
        
            <<control>>
            LOOP
                FETCH c_control BULK COLLECT
                    INTO l_control_tab LIMIT l_limit;
            
                FOR idx IN 1 .. l_control_tab.count
                LOOP
                
                    BEGIN
                    
                        IF l_undo_changes = 1
                        THEN
                            -- undo changes from the previous iteration
                            pk_utils.undo_changes;
                            l_undo_changes := 0;
                        END IF;
                    
                        IF idx > 1
                        THEN
                            -- getting previous institution and area at the begining of the loop because of "continue" instruction
                            g_error            := 'l_prev_institution=' || l_prev_institution || ' l_prev_area=' ||
                                                  l_prev_area;
                            l_prev_institution := l_control_tab(idx - 1).id_institution; -- previous institution
                            l_prev_area        := l_control_tab(idx - 1).id_order_recurr_area; -- previous area
                        END IF;
                    
                        -- updating prof institution
                        g_error            := 'updating institution';
                        l_prof.institution := l_control_tab(idx).id_institution;
                        l_lang             := to_number(nvl(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                                                    l_prof),
                                                            1));
                    
                        -------
                        -- Getting active window interval
                        IF l_prev_institution IS NULL
                           OR l_prev_institution != l_prof.institution
                           OR l_prev_area IS NULL
                           OR l_prev_area != l_control_tab(idx).id_order_recurr_area
                        THEN
                            -- this is only done if current institution is different from the previous institution
                            g_error := 'Call get_order_recurr_cfg / i_order_recurr_area=' || l_control_tab(idx).id_order_recurr_area ||
                                       ' i_interval_name=' || pk_order_recurrence_core.g_cfg_name_active_window ||
                                       ' l_prev_institution=' || l_prev_institution || ' _prof.institution=' ||
                                       l_prof.institution;
                            pk_alertlog.log_debug(g_error);
                            IF NOT get_order_recurr_cfg(i_lang              => l_lang,
                                                        i_prof              => l_prof,
                                                        i_order_recurr_area => l_control_tab(idx).id_order_recurr_area,
                                                        i_interval_name     => g_cfg_name_active_window,
                                                        o_interval_value    => l_interval,
                                                        o_error             => l_error)
                            THEN
                                l_interval := g_active_window_def; -- job must continue processing, assuming default interval
                            END IF;
                        END IF;
                    
                        -------
                        -- getting start and end dates
                        l_dt_start := l_control_tab(idx).dt_last_processed;
                        l_dt_end   := l_sysdate + l_interval;
                    
                        g_error := 'Check l_dt_start and l_dt_end';
                        IF l_dt_start >= l_dt_end
                        THEN
                            CONTINUE; -- nothing to be processed
                        END IF;
                    
                        -------
                        -- Getting recurrence plans info
                        g_error := 'Get planned recurrence events / i_order_plan=' || l_control_tab(idx).id_order_recurr_plan ||
                                   ' i_proc_from_exec_nr=' || l_control_tab(idx).last_exec_order;
                        pk_alertlog.log_debug(g_error);
                        IF NOT get_order_recurr_plan(i_lang              => l_lang,
                                                     i_prof              => l_prof,
                                                     i_order_plan        => l_control_tab(idx).id_order_recurr_plan,
                                                     i_plan_start_date   => l_dt_start,
                                                     i_plan_end_date     => l_dt_end,
                                                     i_proc_from_day     => l_control_tab(idx).dt_last_exec,
                                                     i_proc_from_exec_nr => l_control_tab(idx).last_exec_order,
                                                     o_order_plan        => l_order_plan_tab,
                                                     o_last_exec_reached => l_last_exec_reached,
                                                     o_error             => l_error)
                        THEN
                            -- job must continue processing
                            g_error := 'error found while calling get_order_recurr_plan function / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan;
                            pk_alertlog.log_error(g_error);
                        
                            -- set order recurr plan with error state
                            process_plan_error(l_control_tab(idx).id_order_recurr_plan);
                        
                            CONTINUE;
                        END IF;
                    
                        g_error := 'l_order_plan_tab.COUNT=' || l_order_plan_tab.count;
                        pk_alertlog.log_debug(g_error);
                    
                        -------
                        -- Process executions of all areas
                        IF l_order_plan_tab.count > 0
                        THEN
                            l_exec_to_process := NULL;
                            g_error           := 'ID_ORDER_RECURR_AREA=' || l_control_tab(idx).id_order_recurr_area;
                            CASE
                                WHEN l_control_tab(idx).id_order_recurr_area = g_area_lab_test THEN
                                
                                    ----------
                                    -- LAB_TEST
                                    ----------
                                
                                    /* SELECT DISTINCT ard.id_analysis,
                                                   ard.id_sample_type,
                                                   ar.flg_time,
                                                   ar.flg_priority,
                                                   ard.flg_prn,
                                                   ard.id_room,
                                                   ar.id_exec_institution,
                                                   ard.flg_col_inst,
                                                   e.id_institution,
                                                   ei.id_professional,
                                                   ei.id_software
                                     INTO l_analysis,
                                          l_sample_type,
                                          l_flg_time,
                                          l_flg_priority,
                                          l_flg_prn,
                                          l_room,
                                          l_id_exec_institution,
                                          l_flg_col_inst,
                                          l_institution,
                                          l_professional,
                                          l_software
                                     FROM analysis_req_det ard
                                    INNER JOIN analysis_req ar
                                       ON ar.id_analysis_req = ard.id_analysis_req
                                    INNER JOIN episode e
                                       ON ar.id_episode = e.id_episode
                                    INNER JOIN epis_info ei
                                       ON ei.id_episode = e.id_episode
                                    WHERE ard.id_order_recurrence = l_order_plan_tab(1).id_order_recurrence_plan;*/
                                
                                    g_error := 'Call pk_lab_tests_api_db.create_lab_test_recurrence';
                                    IF NOT
                                        pk_lab_tests_api_db.create_lab_test_recurrence(i_lang     => l_lang,
                                                                                       i_prof     => profissional(l_professional,
                                                                                                                  l_institution,
                                                                                                                  l_software),
                                                                                       i_exec_tab => l_order_plan_tab,
                                                                                       /*i_analysis         => table_number(l_analysis),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_analysis_group   => NULL,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_flg_type         => table_varchar('A'),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_flg_time         => table_varchar(l_flg_time),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_priority         => table_varchar(l_flg_priority),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_flg_prn          => table_varchar(l_flg_prn),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_specimen         => table_number(l_sample_type),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_collection_room  => table_number(l_room),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_exec_institution => table_number(l_id_exec_institution),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          i_flg_col_inst     => table_varchar(l_flg_col_inst),*/
                                                                                       o_exec_to_process => l_exec_to_process,
                                                                                       o_error           => l_error)
                                    THEN
                                        l_undo_changes := 1;
                                        g_error        := 'error found while calling pk_lab_tests_api_db.create_lab_test_recurrence function / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan;
                                        pk_alertlog.log_error(g_error);
                                        --print_exec(l_order_plan_tab);
                                        CONTINUE;
                                    END IF;
                                
                                WHEN l_control_tab(idx).id_order_recurr_area IN (g_area_image_exam, g_area_other_exam) THEN
                                
                                    ----------
                                    -- IMAGE_EXAM or OTHER_EXAM
                                    ----------
                                    g_error := 'Call pk_exams_api_db.create_exam_recurrence';
                                    IF NOT pk_exams_api_db.create_exam_recurrence(i_lang            => l_lang,
                                                                                  i_prof            => l_prof,
                                                                                  i_exec_tab        => l_order_plan_tab,
                                                                                  o_exec_to_process => l_exec_to_process,
                                                                                  o_error           => l_error)
                                    THEN
                                        l_undo_changes := 1;
                                        g_error        := 'error found while calling pk_exams_api_db.create_exam_recurrence function / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan;
                                        pk_alertlog.log_error(g_error);
                                        CONTINUE;
                                    END IF;
                                
                                WHEN l_control_tab(idx).id_order_recurr_area = g_area_pat_education THEN
                                
                                    ----------
                                    -- PATIENT_EDUCATION
                                    ----------
                                    g_error := 'Call pk_patient_education_api_db.create_executions';
                                    IF NOT
                                        pk_patient_education_api_db.create_executions(i_lang            => l_lang,
                                                                                      i_prof            => l_prof,
                                                                                      i_exec_tab        => l_order_plan_tab,
                                                                                      o_exec_to_process => l_exec_to_process,
                                                                                      o_error           => l_error)
                                    THEN
                                        l_undo_changes := 1;
                                        g_error        := 'error found while calling pk_patient_education_api_db.create_executions function / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan;
                                        pk_alertlog.log_error(g_error);
                                        CONTINUE;
                                    END IF;
                                
                                WHEN l_control_tab(idx).id_order_recurr_area = g_area_icnp THEN
                                
                                    ----------
                                    -- ICNP
                                    ----------
                                    g_error := 'call pk_icnp_fo_api_db.create_executions';
                                    IF NOT pk_icnp_fo_api_db.create_executions(i_lang            => l_lang,
                                                                               i_prof            => l_prof,
                                                                               i_exec_tab        => l_order_plan_tab,
                                                                               i_sysdate_tstz    => l_sysdate,
                                                                               o_exec_to_process => l_exec_to_process,
                                                                               o_error           => l_error)
                                    THEN
                                        l_undo_changes := 1;
                                        g_error        := 'error found while calling pk_icnp_fo_api_db.create_executions function / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan;
                                        pk_alertlog.log_error(g_error);
                                        CONTINUE;
                                    END IF;
                                
                                WHEN l_control_tab(idx).id_order_recurr_area = g_area_nnn_noc_outcome THEN
                                
                                    ----------
                                    -- Nursing Care Plan (NANDA/NIC/NOC): NOC Outcome
                                    ----------
                                    g_error := 'call pk_nnn_api_db.create_outcome_recurrence';
                                    IF NOT pk_nnn_api_db.create_outcome_recurrence(i_lang            => l_lang,
                                                                                   i_prof            => l_prof,
                                                                                   i_exec_tab        => l_order_plan_tab,
                                                                                   i_timestamp       => l_sysdate,
                                                                                   o_exec_to_process => l_exec_to_process,
                                                                                   o_error           => l_error)
                                    THEN
                                        l_undo_changes := 1;
                                        g_error        := 'error found while calling pk_nnn_api_db.create_outcome_recurrence function / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan;
                                        pk_alertlog.log_error(g_error);
                                        CONTINUE;
                                    END IF;
                                
                                WHEN l_control_tab(idx).id_order_recurr_area = g_area_nnn_noc_indicator THEN
                                
                                    ----------
                                    -- Nursing Care Plan (NANDA/NIC/NOC): NOC Indicator
                                    ----------
                                    g_error := 'call pk_nnn_api_db.create_indicator_recurrence';
                                    IF NOT pk_nnn_api_db.create_indicator_recurrence(i_lang            => l_lang,
                                                                                     i_prof            => l_prof,
                                                                                     i_exec_tab        => l_order_plan_tab,
                                                                                     i_timestamp       => l_sysdate,
                                                                                     o_exec_to_process => l_exec_to_process,
                                                                                     o_error           => l_error)
                                    THEN
                                        l_undo_changes := 1;
                                        g_error        := 'error found while calling pk_nnn_api_db.create_indicator_recurrence function / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan;
                                        pk_alertlog.log_error(g_error);
                                        CONTINUE;
                                    END IF;
                                
                                WHEN l_control_tab(idx).id_order_recurr_area = g_area_nnn_nic_activity THEN
                                
                                    ----------
                                    -- Nursing Care Plan (NANDA/NIC/NOC): NIC Activity
                                    ----------
                                    g_error := 'call pk_nnn_api_db.create_activity_recurrence';
                                    IF NOT pk_nnn_api_db.create_activity_recurrence(i_lang            => l_lang,
                                                                                    i_prof            => l_prof,
                                                                                    i_exec_tab        => l_order_plan_tab,
                                                                                    i_timestamp       => l_sysdate,
                                                                                    o_exec_to_process => l_exec_to_process,
                                                                                    o_error           => l_error)
                                    THEN
                                        l_undo_changes := 1;
                                        g_error        := 'error found while calling pk_nnn_api_db.create_activity_recurrence function / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan;
                                        pk_alertlog.log_error(g_error);
                                        CONTINUE;
                                    END IF;
                                ELSE
                                
                                    -- Area ID not found, log error and continue processing
                                    g_error := 'Order recurrence area ID not found: ' || l_control_tab(idx).id_order_recurr_area;
                                    pk_alertlog.log_error(g_error);
                                    CONTINUE;
                            END CASE;
                        
                            g_error := 'l_exec_to_process.COUNT=' || l_exec_to_process.count;
                            pk_alertlog.log_debug(g_error);
                        
                            -------
                            -- Updates control table
                            FOR i IN 1 .. l_exec_to_process.count
                            LOOP
                                -- for each plan
                                g_error           := 'Last execution number and dates';
                                l_last_exec_order := l_order_plan_tab(l_order_plan_tab.count).exec_number;
                                l_dt_last_exec    := l_order_plan_tab(l_order_plan_tab.count).exec_timestamp;
                            
                                g_error := 'UPDATE order_recurr_control / id_order_recurr_plan=' || l_exec_to_process(i).id_order_recurrence_plan ||
                                           ' flg_Status=' || l_exec_to_process(i).flg_status || ' l_last_exec_reached=' ||
                                           l_last_exec_reached || ' last_exec_order=' || l_last_exec_order;
                                pk_alertlog.log_debug(g_error);
                            
                                UPDATE order_recurr_control c
                                   SET c.flg_status        = decode(l_last_exec_reached,
                                                                    pk_alert_constant.get_yes,
                                                                    g_flg_status_control_finished,
                                                                    decode(l_exec_to_process(i).flg_status,
                                                                           pk_alert_constant.get_no,
                                                                           g_flg_status_control_outdated,
                                                                           flg_status)),
                                       c.dt_last_processed = l_dt_end,
                                       c.last_exec_order   = l_last_exec_order,
                                       c.dt_last_exec      = l_dt_last_exec
                                 WHERE c.id_order_recurr_plan = l_exec_to_process(i).id_order_recurrence_plan;
                            
                            END LOOP;
                        
                        ELSE
                        
                            -------
                            -- Updates control table
                            g_error := 'UPDATE order_recurr_control / id_order_recurr_plan=' || l_control_tab(idx).id_order_recurr_plan ||
                                       ' l_last_exec_reached=' || l_last_exec_reached;
                            pk_alertlog.log_debug(g_error);
                            UPDATE order_recurr_control c
                               SET c.flg_status        = decode(l_last_exec_reached,
                                                                pk_alert_constant.get_yes,
                                                                g_flg_status_control_finished,
                                                                flg_status),
                                   c.dt_last_processed = l_dt_end
                             WHERE c.id_order_recurr_plan = l_control_tab(idx).id_order_recurr_plan;
                        END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_undo_changes := 1;
                            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
                            -- continue processing other plans
                    END;
                
                    g_error := 'l_undo_changes=' || l_undo_changes;
                    IF l_undo_changes = 1
                    THEN
                        pk_utils.undo_changes;
                    ELSE
                        COMMIT;
                    END IF;
                
                END LOOP;
            
                EXIT WHEN l_control_tab.count < l_limit;
            
            END LOOP control;
        
            CLOSE c_control;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alertlog.log_error(g_error || ' / ' || SQLERRM);
    END set_order_recurr_control;

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
    
        CURSOR c_orcpl(x_id_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE) IS
            SELECT *
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = x_id_order_recurr_plan
               AND orcpl.flg_status = g_plan_status_final;
    
        rec_orcpl   order_recurr_plan%ROWTYPE;
        l_id_market market.id_market%TYPE;
        l_interval  order_recurr_control_cfg.interval_value%TYPE;
    
        l_plan_start_date   TIMESTAMP WITH LOCAL TIME ZONE;
        l_plan_end_date     TIMESTAMP WITH LOCAL TIME ZONE;
        l_last_exec_reached VARCHAR2(1 CHAR);
    
        l_order_plan_exec t_tbl_order_recurr_plan;
    BEGIN
    
        -- getting id_market
        g_error           := 'Call pk_utils.get_institution_market / institution=' || i_prof.institution;
        l_id_market       := pk_utils.get_institution_market(i_lang, i_prof.institution);
        o_order_plan_exec := t_tbl_order_recurr_plan();
    
        -- loop, for each plan
        FOR i IN 1 .. i_order_plan.count
        LOOP
            -- get record from order_recurr_plan table
            g_error := 'get record from order_recurr_plan table, where id_order_recurr_plan is [' || i_order_plan(i) || ']';
            OPEN c_orcpl(i_order_plan(i));
            FETCH c_orcpl
                INTO rec_orcpl;
            CLOSE c_orcpl;
        
            -- getting active window
            g_error := 'Call get_order_recurr_cfg / i_order_recurr_area=' || rec_orcpl.id_order_recurr_area ||
                       ' i_interval_name=' || g_cfg_name_active_window || ' i_id_market=' || l_id_market;
            IF NOT get_order_recurr_cfg(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_order_recurr_area => rec_orcpl.id_order_recurr_area,
                                        i_interval_name     => g_cfg_name_active_window,
                                        i_id_market         => l_id_market,
                                        o_interval_value    => l_interval,
                                        o_error             => o_error)
            THEN
                g_error := 'error while calling get_order_recurr_cfg function, where id_order_recurr_area is [' ||
                           rec_orcpl.id_order_recurr_area || ']';
                RAISE e_user_exception;
            END IF;
        
            l_plan_start_date := rec_orcpl.start_date;
            l_plan_end_date   := l_plan_start_date + l_interval;
        
            -- getting recurrence executions
            IF NOT get_order_recurr_plan(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_order_plan        => rec_orcpl.id_order_recurr_plan,
                                         i_plan_start_date   => l_plan_start_date,
                                         i_plan_end_date     => l_plan_end_date,
                                         o_order_plan        => l_order_plan_exec,
                                         o_last_exec_reached => l_last_exec_reached,
                                         o_error             => o_error)
            THEN
                g_error := 'error while calling get_order_recurr_plan function, where id_order_recurr_plan is [' ||
                           rec_orcpl.id_order_recurr_plan || ']';
                RAISE e_user_exception;
            END IF;
        
            -- updating order_recurrence_control
            IF l_order_plan_exec.count > 0
            THEN
                BEGIN
                    g_error := 'insert into order_recurr_control / id_order_recurr_plan=' || i_order_plan(i);
                    INSERT INTO order_recurr_control
                        (id_order_recurr_plan,
                         dt_last_processed,
                         flg_status,
                         id_order_recurr_area,
                         last_exec_order,
                         dt_last_exec)
                    VALUES
                        (rec_orcpl.id_order_recurr_plan,
                         l_plan_end_date,
                         decode(l_last_exec_reached,
                                pk_alert_constant.get_yes,
                                g_flg_status_control_finished,
                                g_flg_status_control_active),
                         rec_orcpl.id_order_recurr_area,
                         l_order_plan_exec(l_order_plan_exec.count).exec_number,
                         l_order_plan_exec(l_order_plan_exec.count).exec_timestamp);
                EXCEPTION
                    -- validation to avoid errors on calls to prepare_order_recurr_plan using the same plan
                    WHEN dup_val_on_index THEN
                        pk_alertlog.log_debug('Plan id_order_recurr_plan=' || rec_orcpl.id_order_recurr_plan ||
                                              'already exists in order_recurr_control table');
                END;
            END IF;
        
            -- add to o_order_plan_exec
            o_order_plan_exec := o_order_plan_exec MULTISET UNION l_order_plan_exec;
            l_order_plan_exec := NULL;
        
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
    
        CURSOR c_orcpl(x_id_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE) IS
            SELECT *
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = x_id_order_recurr_plan
               AND orcpl.flg_status = g_plan_status_final;
    
        rec_orcpl   order_recurr_plan%ROWTYPE;
        l_id_market market.id_market%TYPE;
        l_interval  order_recurr_control_cfg.interval_value%TYPE;
    
        l_plan_start_date   TIMESTAMP WITH LOCAL TIME ZONE;
        l_plan_end_date     TIMESTAMP WITH LOCAL TIME ZONE;
        l_last_exec_reached VARCHAR2(1 CHAR);
    
        l_order_plan_exec t_tbl_order_recurr_plan;
    BEGIN
    
        -- getting id_market
        g_error     := 'Call pk_utils.get_institution_market / institution=' || i_prof.institution;
        l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        -- loop, for each plan
        FOR i IN 1 .. i_order_plan.count
        LOOP
            -- get record from order_recurr_plan table
            g_error := 'get record from order_recurr_plan table, where id_order_recurr_plan is [' || i_order_plan(i) || ']';
            OPEN c_orcpl(i_order_plan(i));
            FETCH c_orcpl
                INTO rec_orcpl;
            CLOSE c_orcpl;
        
            -- getting active window
            g_error := 'Call get_order_recurr_cfg / i_order_recurr_area=' || rec_orcpl.id_order_recurr_area ||
                       ' i_interval_name=' || g_cfg_name_active_window || ' i_id_market=' || l_id_market;
            IF NOT pk_order_recurrence_core.get_order_recurr_cfg(i_lang              => i_lang,
                                                                 i_prof              => i_prof,
                                                                 i_order_recurr_area => rec_orcpl.id_order_recurr_area,
                                                                 i_interval_name     => g_cfg_name_active_window,
                                                                 i_id_market         => l_id_market,
                                                                 o_interval_value    => l_interval,
                                                                 o_error             => o_error)
            THEN
                g_error := 'error while calling get_order_recurr_cfg function, where id_order_recurr_area is [' ||
                           rec_orcpl.id_order_recurr_area || ']';
                RAISE e_user_exception;
            END IF;
        
            l_plan_start_date := rec_orcpl.start_date;
        
            IF rec_orcpl.regular_interval IS NOT NULL
            THEN
                l_plan_end_date := add_offset_to_tstz(i_offset    => rec_orcpl.regular_interval,
                                                      i_timestamp => l_plan_start_date,
                                                      i_unit      => rec_orcpl.id_unit_meas_regular_interval);
            ELSE
            
                IF rec_orcpl.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_none
                THEN
                    l_plan_end_date := l_plan_start_date + numtodsinterval(1, 'DAY');
                ELSIF rec_orcpl.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_daily
                THEN
                    l_plan_end_date := l_plan_start_date + numtodsinterval(rec_orcpl.repeat_every, 'DAY');
                ELSIF rec_orcpl.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_weekly
                THEN
                    l_plan_end_date := l_plan_start_date + numtodsinterval(7 * rec_orcpl.repeat_every, 'DAY');
                ELSIF rec_orcpl.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_monthly
                THEN
                    l_plan_end_date := l_plan_start_date + numtoyminterval(rec_orcpl.repeat_every, 'MONTH');
                ELSIF rec_orcpl.flg_recurr_pattern = pk_order_recurrence_core.g_flg_recurr_pattern_yearly
                THEN
                    l_plan_end_date := l_plan_start_date + numtoyminterval(rec_orcpl.repeat_every, 'YEAR');
                ELSE
                    l_plan_end_date := l_plan_start_date + 1;
                END IF;
            END IF;
        
            -- getting recurrence executions
            IF NOT get_order_recurr_plan_proc(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_order_plan        => rec_orcpl.id_order_recurr_plan,
                                              i_plan_start_date   => l_plan_start_date,
                                              i_plan_end_date     => l_plan_end_date,
                                              o_order_plan        => l_order_plan_exec,
                                              o_last_exec_reached => l_last_exec_reached,
                                              o_error             => o_error)
            THEN
                g_error := 'error while calling get_order_recurr_plan function, where id_order_recurr_plan is [' ||
                           rec_orcpl.id_order_recurr_plan || ']';
                RAISE e_user_exception;
            END IF;
        
            -- updating order_recurrence_control
            IF l_order_plan_exec.count > 0
               AND l_order_plan_exec.count > 1
            THEN
                BEGIN
                    g_error := 'insert into order_recurr_control / id_order_recurr_plan=' || i_order_plan(i);
                    INSERT INTO order_recurr_control
                        (id_order_recurr_plan,
                         dt_last_processed,
                         flg_status,
                         id_order_recurr_area,
                         last_exec_order,
                         dt_last_exec)
                    VALUES
                        (rec_orcpl.id_order_recurr_plan,
                         l_order_plan_exec(2).exec_timestamp,
                         g_flg_status_control_active,
                         rec_orcpl.id_order_recurr_area,
                         l_order_plan_exec(1).exec_number,
                         l_order_plan_exec(1).exec_timestamp);
                EXCEPTION
                    -- validation to avoid errors on calls to prepare_order_recurr_plan using the same plan
                    WHEN dup_val_on_index THEN
                        pk_alertlog.log_debug('Plan id_order_recurr_plan=' || rec_orcpl.id_order_recurr_plan ||
                                              'already exists in order_recurr_control table');
                END;
            ELSIF rec_orcpl.id_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
            THEN
                BEGIN
                    g_error := 'insert into order_recurr_control / id_order_recurr_plan=' || i_order_plan(i);
                    INSERT INTO order_recurr_control
                        (id_order_recurr_plan,
                         dt_last_processed,
                         flg_status,
                         id_order_recurr_area,
                         last_exec_order,
                         dt_last_exec)
                    VALUES
                        (rec_orcpl.id_order_recurr_plan,
                         l_order_plan_exec(1).exec_timestamp,
                         g_flg_status_control_active,
                         rec_orcpl.id_order_recurr_area,
                         l_order_plan_exec(1).exec_number,
                         l_order_plan_exec(1).exec_timestamp);
                EXCEPTION
                    -- validation to avoid errors on calls to prepare_order_recurr_plan using the same plan
                    WHEN dup_val_on_index THEN
                        pk_alertlog.log_debug('Plan id_order_recurr_plan=' || rec_orcpl.id_order_recurr_plan ||
                                              'already exists in order_recurr_control table');
                END;
            END IF;
        
            -- add to o_order_plan_exec
            l_order_plan_exec := NULL;
        
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
                                              'PREPARE_ORDER_RECURR_PLAN',
                                              o_error);
            RETURN FALSE;
    END prepare_order_recurr_plan;

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
        CURSOR c_plan_control IS
            SELECT orc.flg_status, orc.last_exec_order, orc.dt_last_exec
              FROM order_recurr_control orc
             WHERE orc.id_order_recurr_plan = i_order_recurr_plan;
    BEGIN
        -- get order recurrence plan status
        OPEN c_plan_control;
        FETCH c_plan_control
            INTO o_flg_status, o_last_exec_order, o_dt_last_exec;
        CLOSE c_plan_control;
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
        CURSOR c_orcpl_area(i_plan IN order_recurr_plan.id_order_recurr_plan%TYPE) IS
            SELECT id_order_recurr_area
              FROM order_recurr_plan orcpl
             WHERE orcpl.id_order_recurr_plan = i_plan
               AND orcpl.flg_status = g_plan_status_final;
    
        CURSOR c_orcc_exec_nr(i_plan IN order_recurr_plan.id_order_recurr_plan%TYPE) IS
            SELECT last_exec_order
              FROM order_recurr_control orc
             WHERE orc.id_order_recurr_plan = i_plan;
    
        l_id_market         market.id_market%TYPE;
        l_interval          order_recurr_control_cfg.interval_value%TYPE;
        l_plan_end_date     TIMESTAMP WITH LOCAL TIME ZONE;
        l_last_exec_reached VARCHAR2(1 CHAR);
        l_order_recurr_area order_recurr_area.id_order_recurr_area%TYPE;
        l_order_plan_exec   t_tbl_order_recurr_plan;
    
        l_last_exec_nr PLS_INTEGER;
        l_plan         order_recurr_plan.id_order_recurr_plan%TYPE;
    
        l_sysdate CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        -- getting id_market
        g_error := 'call pk_utils.get_institution_market for institution=' || i_prof.institution;
        pk_alertlog.log_debug(g_error);
        l_id_market := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        -- create a new plan if needed (a copy from current plan will be performed)
        IF i_flg_need_new_plan = pk_alert_constant.g_yes
        THEN
            -- duplicate plan
            g_error := 'duplicate order recurrence plan from id_order_recurr_plan [' || i_order_recurr_plan || ']';
            pk_alertlog.log_debug(g_error, g_package_name);
            IF NOT duplicate_order_recurr_plan(i_lang                   => i_lang,
                                               i_prof                   => i_prof,
                                               i_order_recurr_plan_from => i_order_recurr_plan,
                                               i_flg_dup_control_table  => pk_alert_constant.g_yes, -- to duplicate also order_recurr_control table
                                               i_flg_force_temp_plan    => pk_alert_constant.g_no,
                                               o_order_recurr_plan_to   => l_plan,
                                               o_error                  => o_error)
            THEN
                g_error := 'error found while calling duplicate_order_recurr_plan function';
                RAISE e_user_exception;
            END IF;
        ELSE
            l_plan := i_order_recurr_plan; -- re-use current order recurrence plan
        END IF;
    
        -- get order recurrence area from order_recurr_plan table
        g_error := 'get order recurrence area from order_recurr_plan table, where id_order_recurr_plan is [' || l_plan || ']';
        pk_alertlog.log_debug(g_error);
        OPEN c_orcpl_area(l_plan);
        FETCH c_orcpl_area
            INTO l_order_recurr_area;
        CLOSE c_orcpl_area;
    
        -- getting active window
        g_error := 'call get_order_recurr_cfg / i_order_recurr_area=' || l_order_recurr_area || ' i_interval_name=' ||
                   g_cfg_name_active_window || ' i_id_market=' || l_id_market;
        pk_alertlog.log_debug(g_error);
        IF NOT get_order_recurr_cfg(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_order_recurr_area => l_order_recurr_area,
                                    i_interval_name     => g_cfg_name_active_window,
                                    i_id_market         => l_id_market,
                                    o_interval_value    => l_interval,
                                    o_error             => o_error)
        THEN
            g_error := 'error while calling get_order_recurr_cfg function, where id_order_recurr_area is [' ||
                       l_order_recurr_area || ']';
            RAISE e_user_exception;
        END IF;
    
        l_plan_end_date := i_execution_timestamp + l_interval;
    
        -- get last exec_number from control table
        g_error := 'get last exec_number from control table, where id_order_recurr_plan is [' || l_plan || ']';
        pk_alertlog.log_debug(g_error);
        OPEN c_orcc_exec_nr(l_plan);
        FETCH c_orcc_exec_nr
            INTO l_last_exec_nr;
        CLOSE c_orcc_exec_nr;
    
        -- check if exec_number is greater than the maximum allowed exec_number from control table
        IF l_last_exec_nr IS NOT NULL
           AND i_execution_number < l_last_exec_nr
        THEN
            -- getting recurrence executions
            IF NOT get_order_recurr_plan(i_lang                   => i_lang,
                                         i_prof                   => i_prof,
                                         i_order_plan             => l_plan,
                                         i_plan_start_date        => i_execution_timestamp,
                                         i_plan_end_date          => l_plan_end_date,
                                         i_proc_from_day          => i_execution_timestamp,
                                         i_proc_from_exec_nr      => i_execution_number,
                                         i_flg_validate_proc_from => pk_alert_constant.g_no,
                                         o_order_plan             => l_order_plan_exec,
                                         o_last_exec_reached      => l_last_exec_reached,
                                         o_error                  => o_error)
            THEN
                g_error := 'error found while calling get_order_recurr_plan function, where id_order_recurr_plan is [' ||
                           l_plan || ']';
                RAISE e_user_exception;
            END IF;
        
            g_error := 'updating order_recurr_control table';
            pk_alertlog.log_debug(g_error);
            -- updating order_recurrence_control
            UPDATE order_recurr_control
               SET dt_last_processed = l_plan_end_date,
                   flg_status        = decode(l_last_exec_reached,
                                              pk_alert_constant.get_yes,
                                              g_flg_status_control_finished,
                                              g_flg_status_control_active),
                   last_exec_order   = l_order_plan_exec(l_order_plan_exec.count).exec_number,
                   dt_last_exec      = l_order_plan_exec(l_order_plan_exec.count).exec_timestamp
             WHERE id_order_recurr_plan = l_plan;
        
            -- remove current execution (the one that caused the plan shift)
            SELECT t_rec_order_recurr_plan(plan.id_order_recurrence_plan, plan.exec_number, plan.exec_timestamp)
              BULK COLLECT
              INTO o_order_plan_exec
              FROM TABLE(CAST(l_order_plan_exec AS t_tbl_order_recurr_plan)) plan
             WHERE plan.exec_number > i_execution_number;
        
            -- last execution is being addressed here
        ELSIF l_last_exec_nr IS NOT NULL
              AND i_execution_number = l_last_exec_nr
        THEN
            g_error := 'updating order_recurr_control table for last execution';
            pk_alertlog.log_debug(g_error);
            -- updating order_recurrence_control
            UPDATE order_recurr_control
               SET dt_last_processed = l_sysdate,
                   last_exec_order   = i_execution_number,
                   dt_last_exec      = i_execution_timestamp
             WHERE id_order_recurr_plan = l_plan;
        
            -- no executions to process in this plan
            o_order_plan_exec := t_tbl_order_recurr_plan();
        
        ELSE
            g_error := 'execution number [' || i_execution_number ||
                       '] cannot be greater than the allowed maximum execution number from control table [' ||
                       l_last_exec_nr || ']';
            RAISE e_user_exception;
        END IF;
    
        -- assign plan
        o_order_recurr_plan := l_plan;
    
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
        -- debug info for input arguments
        pk_alertlog.log_debug('SET_FOR_EDIT_ORDER_RECURR_PLAN function calling parameters:' || chr(10) || 'i_lang=' ||
                              i_lang || chr(10) || 'i_prof=(' || i_prof.id || ',' || i_prof.institution || ',' ||
                              i_prof.software || ')' || chr(10) || 'i_order_recurr_plan_old=' ||
                              i_order_recurr_plan_old || chr(10) || 'i_order_recurr_plan_new=' ||
                              i_order_recurr_plan_new || chr(10) || 'i_flg_discard_old_plan=' ||
                              i_flg_discard_old_plan,
                              g_package_name);
    
        -- check if i_order_recurr_plan_old should be discarded or not
        IF i_flg_discard_old_plan = pk_alert_constant.g_yes
           AND i_order_recurr_plan_old IS NOT NULL
        THEN
            -- discard job control record for old plan
            pk_alertlog.log_debug('interrupt in order_recurr_control table the id_order_recurr_plan=' ||
                                  i_order_recurr_plan_old,
                                  g_package_name);
            UPDATE order_recurr_control c
               SET c.flg_status = g_flg_status_control_interrupt
             WHERE c.id_order_recurr_plan = i_order_recurr_plan_old;
        END IF;
    
        -- call set_order_recurr_plan to finalize new order recurrence plan
        IF NOT set_order_recurr_plan(i_lang                    => i_lang,
                                     i_prof                    => i_prof,
                                     i_order_recurr_plan       => i_order_recurr_plan_new,
                                     o_order_recurr_option     => o_order_recurr_option,
                                     o_final_order_recurr_plan => o_final_order_recurr_plan,
                                     o_error                   => o_error)
        THEN
            g_error := 'error found while calling set_order_recurr_plan function, where id_order_recurr_plan is [' ||
                       i_order_recurr_plan_new || ']';
            RAISE e_user_exception;
        END IF;
        -- if recurrence plan is not needed, then o_final_order_recurr_plan will be null
    
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
        g_error := 'updating order_recurr_control table';
        pk_alertlog.log_debug(g_error);
    
        -- updating order_recurrence_control
        UPDATE order_recurr_control
           SET flg_status = g_flg_status_control_finished
         WHERE id_order_recurr_plan = i_order_recurr_plan;
    
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

    FUNCTION get_recurr_order_option
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_order_recurr_plan IN order_recurr_plan.id_order_recurr_plan%TYPE
    ) RETURN NUMBER IS
        l_ret order_recurr_plan.id_order_recurr_option%TYPE;
    BEGIN
        IF i_order_recurr_plan IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT a.id_order_recurr_option
          INTO l_ret
          FROM order_recurr_plan a
         WHERE a.id_order_recurr_plan = i_order_recurr_plan;
        RETURN l_ret;
    END get_recurr_order_option;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_order_recurrence_core;
/
