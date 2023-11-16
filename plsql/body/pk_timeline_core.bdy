/*-- Last Change Revision: $Rev: 2027793 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_timeline_core IS

    /*******************************************************************************************************************************************
    * Nome :                          initialize                                                                                               *
    * Descrição:  initialize all constants and global variables needed in the timeline                                                         *
    *                                                                                                                                          *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @raises                         Generic oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION initialize
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error VARCHAR2(4000);
        user_exception EXCEPTION;
    BEGIN
        pk_alertlog.log_debug('get_timezone');
        IF NOT pk_date_utils.get_timezone(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_timezone => NULL,
                                          o_timezone => g_tl_timezone,
                                          o_error    => o_error)
        THEN
            RAISE user_exception;
        END IF;
    
        pk_alertlog.log_debug('date_hour_send_format');
        pk_alert_constant.date_hour_send_format(i_prof);
        pk_alertlog.log_debug('get_timescale_id');
        pk_alert_constant.get_timescale_id;
        pk_alertlog.log_debug('get_timezone');
        pk_alert_constant.get_timezone(i_lang, i_prof, o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INITIALIZE',
                                              'U',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INITIALIZE',
                                              o_error);
            RETURN FALSE;
    END;

    /*******************************************************************************************************************************************
    * Nome :                          truncate_date_to_begin_block                                                                             *
    * Descrição:                      Return de begin date of the block                                                                                            *
    *                                                                                                                                          *
    * @param I_LANG                   language ID                                                                                              *
    * @param I_PROF                   Profissional, institution and software ID's                                                              *
    * @param ID_TL_TIMELINE           ID da TIMELINE                                                                                           *
    * @param O_ERROR                  Error                                                                                                    *
    * @param I_DIRECTION              Movement direction                                                                                       *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return de begin date of the block , and trunc(sysdate) if an error occurred                              *
    * @raises                         Generic oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION truncate_date_to_begin_block
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE,
        id_tl_scale    IN tl_scale.id_tl_scale%TYPE,
        i_direction    IN VARCHAR2,
        i_date         IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN DATE IS
        g_error      VARCHAR2(4000);
        l_begin_date DATE;
        l_year       NUMBER(4) := to_number(to_char(to_date(i_date, pk_alert_constant.g_date_hour_send_format),
                                                    g_format_mask_year));
    BEGIN
        pk_alertlog.log_debug('Begin');
        IF id_tl_scale = pk_alert_constant.g_decade
        THEN
            pk_alertlog.log_debug('IF i_direction = ''RIGHT'' ');
            IF i_direction = 'RIGHT'
            THEN
                l_begin_date := to_date(l_year - MOD(l_year, 10) || '0101000000',
                                        pk_alert_constant.g_date_hour_send_format);
            ELSE
                l_begin_date := to_date(l_year - MOD(l_year, 10) || '1231235959',
                                        pk_alert_constant.g_date_hour_send_format);
            END IF;
        ELSIF id_tl_scale = pk_alert_constant.g_year
        THEN
            IF i_direction = 'RIGHT'
            THEN
                l_begin_date := to_date(to_char(to_date(i_date, pk_alert_constant.g_date_hour_send_format),
                                                g_format_mask_year) || '0101000000',
                                        pk_alert_constant.g_date_hour_send_format);
            ELSE
                l_begin_date := last_day(to_date(to_char(to_date(i_date, pk_alert_constant.g_date_hour_send_format),
                                                         g_format_mask_year) || '1231235959',
                                                 pk_alert_constant.g_date_hour_send_format)) - 1;
            END IF;
        ELSIF id_tl_scale = pk_alert_constant.g_month
        THEN
            IF i_direction = 'RIGHT'
            THEN
                l_begin_date := to_date(to_char(to_date(i_date, pk_alert_constant.g_date_hour_send_format),
                                                g_format_mask_month) || '01000000',
                                        pk_alert_constant.g_date_hour_send_format);
            ELSE
                l_begin_date := (to_date(to_char(last_day(to_date(i_date, pk_alert_constant.g_date_hour_send_format)),
                                                 g_format_mask_day) || '235959',
                                         pk_alert_constant.g_date_hour_send_format));
            END IF;
        ELSIF id_tl_scale = pk_alert_constant.g_week
        THEN
            IF i_direction = 'RIGHT'
            THEN
                l_begin_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                 i_timestamp => to_date(i_date,
                                                                                        pk_alert_constant.g_date_hour_send_format),
                                                                 i_format    => 'DAY');
            ELSE
                l_begin_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                 i_timestamp => to_date(i_date,
                                                                                        pk_alert_constant.g_date_hour_send_format) +
                                                                                INTERVAL '7' DAY,
                                                                 i_format    => 'DAY') + 1 - INTERVAL '1' SECOND;
            END IF;
        ELSIF id_tl_scale = pk_alert_constant.g_day
        THEN
            IF i_direction = 'RIGHT'
            THEN
                l_begin_date := round(to_date(i_date, pk_alert_constant.g_date_hour_send_format),
                                      g_format_mask_short_day);
            ELSE
                l_begin_date := round(to_date(i_date, pk_alert_constant.g_date_hour_send_format),
                                      g_format_mask_short_day);
            END IF;
        
        ELSIF id_tl_scale = pk_alert_constant.g_shift
        THEN
            IF i_direction = 'RIGHT'
            THEN
                l_begin_date := round(to_date(i_date, pk_alert_constant.g_date_hour_send_format),
                                      g_format_mask_short_day);
            ELSE
                l_begin_date := round(to_date(i_date, pk_alert_constant.g_date_hour_send_format),
                                      g_format_mask_short_day);
            END IF;
        END IF;
        --
        RETURN l_begin_date;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNCATE_DATE_TO_BEGIN_BLOCK',
                                              o_error);
            RETURN SYSDATE - 1000000;
    END;

    /*******************************************************************************************************************************************
    * Nome :                          GET_COLUMN_NUMBER                                                                                        *
    * Descrição:  Return the number ofcolumns viewed on timeline                                                                               *
    *                                                                                                                                          *
    * @param I_LANG                   language ID                                                                                              *
    * @param I_PROF                   Profissional, institution and software ID's                                                              *
    * @param ID_TL_TIMELINE           ID da TIMELINE                                                                                           *
    * @param I_ID_SCALE               ID da escala                                                                                             *
    * @param O_ERROR                  Devolução do erro                                                                                        *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return true if no errors occurred and false otherwise                                                    *
    * @raises                         Generic oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/16                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_column_number
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        id_tl_timeline IN tl_timeline.id_tl_timeline%TYPE DEFAULT 1,
        i_id_scale     IN NUMBER DEFAULT 1,
        o_error        OUT t_error_out
        
    ) RETURN NUMBER IS
        l_return NUMBER;
        g_error  VARCHAR2(4000);
    
    BEGIN
        pk_alertlog.log_debug('Mark 1');
        SELECT s.num_columns
          INTO l_return
          FROM tl_scale s
         WHERE s.id_tl_scale = i_id_scale;
        --
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_COLUMN_NUMBER',
                                              o_error);
            RETURN 10;
    END;

    /*******************************************************************************************************************************************
    * Nome :                          GET_TOTAL_COLUMNS                                                                                        *
    * Descrição:  Return the total column number to send in the buffer                                                                         *
    *                                                                                                                                          *
    * @param I_LANG                   language ID                                                                                              *
    * @param I_PROF                   Profissional, institution and software ID's                                                              *
    * @param ID_TL_TIMELINE           ID da TIMELINE                                                                                           *
    * @param I_ID_TL_SCALE               ID da escala                                                                                             *
    * @param I_BLOCK_REQ_TIMELINE     ID da escala                                                                                             *
    * @param O_ERROR                  Devolução do erro                                                                                        *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return number of columns or 60 if an error occurred                                                      *
    * @raises                         Generic oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_total_columns
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        id_tl_timeline     IN tl_timeline.id_tl_timeline%TYPE,
        i_block_req_number IN NUMBER,
        id_tl_scale        IN NUMBER,
        i_direction        IN VARCHAR2,
        i_reference_date   IN DATE,
        o_error            OUT t_error_out
    ) RETURN NUMBER IS
        g_error               VARCHAR2(4000);
        l_block_req_number    NUMBER(4);
        l_block_size          NUMBER(4) := 10;
        l_total_columns       NUMBER(24);
        l_total_hours         NUMBER(24);
        l_inst_shift_duration NUMBER(24);
        l_mod_value           NUMBER(24);
        l_div_value           NUMBER(24);
    
        user_exception EXCEPTION;
        l_date_aux DATE;
    BEGIN
        pk_alertlog.log_debug('Mark 1');
        IF i_block_req_number IS NULL
        THEN
            BEGIN
                pk_alertlog.log_debug('i_block_req_number pk_sysconfig.get_config');
                l_block_req_number := to_number(pk_sysconfig.get_config('TL_BUFFER_SIZE.' || id_tl_timeline,
                                                                        i_prof => i_prof));
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alertlog.log_fatal(g_error);
                    g_error := 'Timeline-' || id_tl_timeline || '-' ||
                               pk_message.get_message(i_lang, 'TL_BUFFER_SIZE_ERROR');
                    RAISE user_exception;
            END;
        
        ELSE
            pk_alertlog.log_debug('i_block_req_number ELSE');
            l_block_req_number := i_block_req_number;
        END IF;
        --
        -- Collumn number is fixed to all scales except MONTH (number of days is variable) and SHIFT (shift duration in hours is variable)
        IF id_tl_scale = pk_alert_constant.g_shift
        THEN
            -- Size of each block depending of shift duration
            -- It is necessary guarantee that returned information has always hours information since hour 00:00:00 to 23:59:59,
            -- because FLASH is expecting block with complete days information.
        
            -- Get shift duration to current institution
            pk_alertlog.log_debug('GET institution shift duration');
            l_inst_shift_duration := pk_sysconfig.get_config('TIMELINE_CARDEX_SHIFT_DURATION', i_prof);
        
            -- Number of hours that will be returned to FLASH (if Rest of division is zero, in other words, 
            -- when number of blocks to return represent just one day information)
            l_total_hours := l_inst_shift_duration * l_block_req_number;
            -- Rest of division of total hours by 24
            l_mod_value := MOD(l_total_hours, g_daily_hours);
            -- Result of division of total hours by 24
            l_div_value := l_total_hours / g_daily_hours;
        
            -- IF number of blocks are not multiple of 24 (number of hours in one days)
            IF l_mod_value != 0
            THEN
                -- if cail(2.3) = 3; ceil(-25.3) = -25
                l_total_hours := ceil(l_div_value) * g_daily_hours;
            END IF;
        
            l_total_columns := l_total_hours;
        
        ELSIF id_tl_scale != pk_alert_constant.g_month
        THEN
            l_block_size    := get_column_number(i_lang, i_prof, id_tl_timeline, id_tl_scale, o_error);
            l_total_columns := l_block_size * l_block_req_number;
        
        ELSE
            IF i_direction = 'RIGHT'
            THEN
                l_date_aux      := add_months(i_reference_date, l_block_req_number);
                l_total_columns := ceil(l_date_aux - i_reference_date) - 1;
            ELSIF i_direction = 'LEFT'
            THEN
                l_date_aux      := add_months(i_reference_date, -1 * l_block_req_number);
                l_total_columns := ceil(i_reference_date - l_date_aux);
            END IF;
        
        END IF;
        --
        RETURN l_total_columns;
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TOTAL_COLUMNS',
                                              'U',
                                              o_error);
            RETURN 60;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TOTAL_COLUMNS',
                                              o_error);
            RETURN 60;
    END;

    /*******************************************************************************************************************************************
    *GET_iterative_DATE Build the output dates using an iterative process                                                                      *
    *                                                                                                                                          *
    * @param i_lang                   Language ID                                                                                              *                                            *
    * @param REFERENCE_DATE           Reference date for the requested information                                                             *
    * @param LEFT_COLUMNS             Number of columns requeted at the left side of the reference_date                                        *
    * @param RIGHT_COLUMNS            Number of columns requeted at the right side of the reference_date                                       *
    * @param I_PATIENT                ID Patient                                                                                               *
    * @param ID_TL_SCALE              Scale ID                                                                                                 *
    * @param OUTPUT ERROR                                                                                                                      *
    *                                                                                                                                          *
    * @value out                                                                                                                               *
    *                                                                                                                                          *
    * @return                         Return false if exist an error and true otherwise                                                        *
    *                                                                                                                                          *
    * @raises                         Raise an exception in generic oracle error                                                               *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/29                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_iterative_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        reference_date IN DATE,
        left_columns   IN NUMBER,
        right_columns  IN NUMBER,
        i_patient      IN NUMBER DEFAULT NULL,
        id_tl_scale    IN NUMBER
    ) RETURN tl_tab_reg_date IS
        o_error t_error_out;
        user_exception EXCEPTION;
        l_dt_begin_scale    DATE;
        l_dt_end_scale      DATE;
        l_actual_date_scale DATE;
        l_left_columns      NUMBER(24);
        l_right_columns     NUMBER(24);
        --TYPE rec_episode_type IS TABLE OF tl_transaction_data%ROWTYPE INDEX BY BINARY_INTEGER;
        shift_duration_exception EXCEPTION;
    
    BEGIN
        g_tab_reg_date.delete;
    
        IF nvl(left_columns, -1) < 0
           OR nvl(right_columns, -1) < 0
        THEN
            g_error := 'erro para parametrizar';
            RAISE user_exception;
        END IF;
    
        pk_alertlog.log_debug('Mark 1');
        --
        -- DÉCADE
        IF id_tl_scale = pk_alert_constant.g_decade
        THEN
            pk_alertlog.log_debug('GET_DECADE');
            FOR i IN (-1 * left_columns + 1) .. right_columns
            LOOP
                g_tab_reg_date.extend;
                g_tab_reg_date(g_tab_reg_date.last) := tl_reg_date(to_date(rpad((to_number(to_char(reference_date,
                                                                                                   g_format_mask_year)) +
                                                                                (i - 1)) - MOD((to_number(to_char(reference_date,
                                                                                                                  g_format_mask_year)) +
                                                                                               (i - 1)),
                                                                                               10),
                                                                                
                                                                                4,
                                                                                '0') || '0101000000',
                                                                           pk_alert_constant.g_date_hour_send_format),
                                                                   to_date(rpad((to_number(to_char(reference_date,
                                                                                                   g_format_mask_year)) +
                                                                                (i - 1)),
                                                                                4,
                                                                                '0') || '0101000000',
                                                                           pk_alert_constant.g_date_hour_send_format),
                                                                   to_date(rpad((to_number(to_char(reference_date,
                                                                                                   g_format_mask_year)) +
                                                                                (i - 1)),
                                                                                4,
                                                                                '0') || '1231235959',
                                                                           pk_alert_constant.g_date_hour_send_format),
                                                                   NULL);
            END LOOP;
            -- YEAR
        ELSIF id_tl_scale = pk_alert_constant.g_year
        THEN
            pk_alertlog.log_debug('GET_YEAR');
            FOR i IN (-1 * left_columns + 1) .. right_columns
            LOOP
                g_tab_reg_date.extend;
                g_tab_reg_date(g_tab_reg_date.last) := tl_reg_date(add_months(trunc(reference_date, g_format_mask_year),
                                                                              floor((i - 1) / 12) * 12),
                                                                   add_months(trunc(reference_date, g_format_mask_year),
                                                                              (i - 1)),
                                                                   last_day(add_months(trunc(reference_date,
                                                                                             g_format_mask_year),
                                                                                       (i - 1))) + 1 - g_one_second,
                                                                   NULL);
            END LOOP;
            -- MONTH
        ELSIF id_tl_scale = pk_alert_constant.g_month
        THEN
            pk_alertlog.log_debug('GET_MONTH');
            FOR i IN (-1 * left_columns) .. right_columns
            LOOP
                l_dt_begin_scale    := trunc(reference_date + i, g_format_mask_short_day);
                l_dt_end_scale      := trunc(reference_date + i + 1, g_format_mask_short_day) - g_one_second;
                l_actual_date_scale := trunc(reference_date + i, g_format_mask_short_month);
                g_tab_reg_date.extend;
                g_tab_reg_date(g_tab_reg_date.last) := tl_reg_date(l_actual_date_scale,
                                                                   l_dt_begin_scale,
                                                                   l_dt_end_scale,
                                                                   NULL);
            END LOOP;
        
            --WEEK
        ELSIF id_tl_scale = pk_alert_constant.g_week
        THEN
            pk_alertlog.log_debug('GET_WEEK');
            IF left_columns > 0
               AND nvl(right_columns, 0) = 0
            THEN
                l_right_columns := right_columns;
                l_left_columns  := left_columns + 1;
            ELSE
                l_left_columns  := left_columns;
                l_right_columns := right_columns;
            END IF;
            FOR i IN (-1 * l_left_columns) .. l_right_columns - 1
            LOOP
                l_actual_date_scale := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                        i_timestamp => reference_date + i);
                l_dt_begin_scale    := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                        i_timestamp => l_actual_date_scale,
                                                                        i_format    => 'DAY');
                l_dt_end_scale      := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                        i_timestamp => l_actual_date_scale,
                                                                        i_format    => 'DAY') + INTERVAL '7'
                                       DAY - g_one_second;
                g_tab_reg_date.extend;
                g_tab_reg_date(g_tab_reg_date.last) := tl_reg_date(l_actual_date_scale,
                                                                   l_dt_begin_scale,
                                                                   l_dt_end_scale,
                                                                   NULL);
            END LOOP;
            --DAY
        ELSIF id_tl_scale = pk_alert_constant.g_day
        THEN
            pk_alertlog.log_debug('GET_DAY');
            FOR i IN (-1 * left_columns + 1) .. right_columns
            LOOP
                g_tab_reg_date.extend;
                g_tab_reg_date(g_tab_reg_date.last) := tl_reg_date((round(reference_date, g_format_mask_short_hour) +
                                                                   (i - 1) / g_daily_hours),
                                                                   (round(reference_date, g_format_mask_short_hour) +
                                                                   (i - 1) / g_daily_hours),
                                                                   ((round(reference_date, g_format_mask_short_hour) +
                                                                   (i - 1) / g_daily_hours) + 1 / g_daily_hours) -
                                                                   g_one_second,
                                                                   pk_date_utils.get_string_tstz_str(i_lang,
                                                                                                     i_prof,
                                                                                                     (round(reference_date,
                                                                                                            g_format_mask_short_hour) +
                                                                                                     (i - 1) /
                                                                                                     g_daily_hours)));
            END LOOP;
            --SHIFT
        ELSIF id_tl_scale = pk_alert_constant.g_shift
        THEN
            FOR i IN (-1 * left_columns + 1) .. right_columns
            LOOP
                g_tab_reg_date.extend;
                g_tab_reg_date(g_tab_reg_date.last) := tl_reg_date((round(reference_date, g_format_mask_short_hour) +
                                                                   (i - 1) / g_daily_hours),
                                                                   (round(reference_date, g_format_mask_short_hour) +
                                                                   (i - 1) / g_daily_hours),
                                                                   ((round(reference_date, g_format_mask_short_hour) +
                                                                   (i - 1) / g_daily_hours) + 1 / g_daily_hours) -
                                                                   g_one_second,
                                                                   pk_date_utils.get_string_tstz_str(i_lang,
                                                                                                     i_prof,
                                                                                                     (round(reference_date,
                                                                                                            g_format_mask_short_hour) +
                                                                                                     (i - 1) /
                                                                                                     g_daily_hours)));
            END LOOP;
        END IF;
        --
        RETURN g_tab_reg_date;
    EXCEPTION
        WHEN shift_duration_exception THEN
            g_error := pk_message.get_message(i_lang, ' common_m001 ') || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ERROR_SHIFT_DURATION_NOT_DEFINED',
                                              'U',
                                              o_error);
            RETURN g_tab_reg_date;
        WHEN user_exception THEN
            g_error := pk_message.get_message(i_lang, ' common_m001 ') || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ITERATIVE_DATE',
                                              'U',
                                              o_error);
            RETURN g_tab_reg_date;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ITERATIVE_DATE',
                                              o_error);
            RETURN g_tab_reg_date;
    END;

    /*******************************************************************************************************************************************
    * Nome :                          GET_DECADE_CURSOR                                                                                        *
    * Descrição:  Décade cursor                                                                                                                *
    *                                                                                                                                          *
    * @param I_LANG                   ID Language                                                                                              *
    * @param I_DECADE                 Décade                                                                                                   *
    * @param I_TOTAL_COLUMN_NUMBER_RIGHTTotal number of columns that must be send to the right side of  the screen                             *
    * @param I_TOTAL_COLUMN_NUMBER_LEFTTotal number of columns thet must be send to the left side ofthe screen                                 *
    * @param I_PATIENT                ID patient                                                                                               *
    * @param I_ID_TL_SCALE            ID scale                                                                                               *
    * @param O_CURSOR_OUT             Output cursor                                                                                            *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Décade cursor                                                                                            *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_decade_cursor
    (
        i_lang                      IN VARCHAR2,
        i_total_column_number_right IN NUMBER,
        i_total_column_number_left  IN NUMBER,
        i_patient                   IN NUMBER,
        i_begin_date                IN DATE,
        i_id_tl_scale               IN NUMBER,
        o_cursor_out                OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error VARCHAR2(4000);
    BEGIN
        pk_alertlog.log_debug('get_iterative_date');
        --
        g_tab_reg_date.delete;
        g_tab_reg_date := get_iterative_date(i_lang,
                                             NULL,
                                             i_begin_date,
                                             i_total_column_number_left,
                                             i_total_column_number_right,
                                             i_patient,
                                             i_id_tl_scale);
    
        pk_alertlog.log_debug('o_cursor_out');
        --
        DECLARE
        
        BEGIN
            OPEN o_cursor_out FOR
                SELECT pk_message.get_message(i_lang, 'TL_DECADE') ||
                       to_number(to_char(scale.actual_date, g_format_mask_year)) ||
                       pk_message.get_message(i_lang, 'TL_DECADE_STR_1') BLOCK,
                       ----------------------------BLOCK
                       lpad(to_char(scale.dt_begin, g_format_mask_year), 4, '0') upper_axis,
                       -----------------------------upper_axis
                       to_number(to_char(scale.dt_begin, g_format_mask_year)) ||
                       pk_message.get_message(i_lang, 'TL_DECADE_STR_1') lower_axis,
                       -----------------------lower_axis
                       to_char((scale.dt_begin), pk_alert_constant.g_date_hour_send_format) dt_begin,
                       ------------------------dt_begin
                       to_char((scale.dt_end), pk_alert_constant.g_date_hour_send_format) dt_end,
                       ----------------------dt_end
                       --actual_date        actual_day,
                       scale.dt_begin_tzh dt_begin_tzh
                  FROM (TABLE(g_tab_reg_date)) scale
                 ORDER BY decode(i_total_column_number_right,
                                 0,
                                 -1 * to_number(to_char(scale.actual_date, 'J')),
                                 to_number(to_char(scale.actual_date, 'J'))) ASC,
                          dt_begin ASC;
        END;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DECADE_CURSOR',
                                              o_error);
            pk_types.open_my_cursor(o_cursor_out);
            RETURN FALSE;
        
    END;

    /*******************************************************************************************************************************************
    * Nome :                          GET_YEAR_CURSOR                                                                                          *
    * Descrição:  Year cursor                                                                                                                  *
    *                                                                                                                                          *
    * @param I_LANG                   ID Language                                                                                              *
    * @param I_TOTAL_COLUMN_NUMBER_RIGHTTotal number of columns that must be send to the right side of  the screen                             *
    * @param I_TOTAL_COLUMN_NUMBER_LEFTTotal number of columns thet must be send to the left side ofthe screen                                 *
    * @param I_PATIENT                ID patient                                                                                               *
    * @param I_ID_TL_SCALE            ID scale                                                                                               *
    * @param O_CURSOR_OUT             Output cursor                                                                                            *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Year cursor                                                                                              *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_year_cursor
    (
        i_lang                      IN VARCHAR2,
        i_total_column_number_right IN NUMBER,
        i_total_column_number_left  IN NUMBER,
        i_patient                   IN NUMBER,
        i_begin_date                IN DATE,
        i_id_tl_scale               IN NUMBER,
        o_cursor_out                OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error VARCHAR2(4000);
    BEGIN
        pk_alertlog.log_debug('get_iterative_date');
        --
        g_tab_reg_date.delete;
        g_tab_reg_date := get_iterative_date(i_lang,
                                             NULL,
                                             i_begin_date,
                                             i_total_column_number_left,
                                             i_total_column_number_right,
                                             i_patient,
                                             i_id_tl_scale);
        --    
        pk_alertlog.log_debug('o_cursor_out');
        BEGIN
            OPEN o_cursor_out FOR
                SELECT pk_message.get_message(i_lang, 'TL_YEAR') ||
                       to_number(to_char(scale.actual_date, g_format_mask_year)) BLOCK,
                       ----------------------------BLOCK
                       
                       pk_message.get_message(i_lang,
                                              'TL_MON_' || to_number(to_char(scale.dt_begin, g_format_mask_short_month))) upper_axis,
                       -----------------------------upper_axis
                       to_number(to_char(scale.dt_begin, g_format_mask_year)) lower_axis,
                       -----------------------lower_axis
                       to_char((scale.dt_begin), pk_alert_constant.g_date_hour_send_format) dt_begin,
                       ------------------------dt_begin
                       to_char((scale.dt_end), pk_alert_constant.g_date_hour_send_format) dt_end,
                       ----------------------dt_end
                       --actual_date        actual_day,
                       scale.dt_begin_tzh dt_begin_tzh
                  FROM TABLE(g_tab_reg_date) scale
                 ORDER BY decode(i_total_column_number_right,
                                 0,
                                 -1 * to_number(to_char(scale.actual_date, 'J')),
                                 to_number(to_char(scale.actual_date, 'J'))) ASC,
                          dt_begin ASC;
        
        END;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_YEAR_CURSOR',
                                              o_error);
            pk_types.open_my_cursor(o_cursor_out);
            RETURN FALSE;
    END;

    /*******************************************************************************************************************************************
    * Nome :                          GET_MONTH_CURSOR                                                                                         *
    * Descrição:  MONTH cursor                                                                                                                 *
    *                                                                                                                                          *
    * @param I_LANG                   ID Language                                                                                              *
    * @param I_TOTAL_COLUMN_NUMBER_RIGHTTotal number of columns that must be send to the right side of  the screen                             *
    * @param I_TOTAL_COLUMN_NUMBER_LEFTTotal number of columns thet must be send to the left side ofthe screen                                 *
    * @param I_PATIENT                ID patient                                                                                               *
    * @param I_ID_TL_SCALE            ID scale                                                                                                 *
    * @param O_CURSOR_OUT             Output cursor                                                                                            *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         MONTH cursor                                                                                             *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_month_cursor
    (
        i_lang                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_total_column_number_right IN NUMBER,
        i_total_column_number_left  IN NUMBER,
        i_patient                   IN NUMBER,
        i_begin_date                IN DATE,
        i_id_tl_scale               IN NUMBER,
        o_cursor_out                OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error           VARCHAR2(4000);
        l_date_format     sys_config.value%TYPE := NULL;
        l_tbl_date_format table_varchar := table_varchar();
    
        l_date_short_format     sys_config.value%TYPE := NULL;
        l_tbl_date_short_format table_varchar := table_varchar();
    BEGIN
        g_error           := 'Error fetching DATE_FORMAT sys_config';
        l_date_format     := upper(pk_sysconfig.get_config('DATE_FORMAT', i_prof));
        l_tbl_date_format := pk_string_utils.str_split(i_list => l_date_format, i_delim => '-');
    
        g_error                 := 'Error fetching DATE_MONTH_DAY sys_config';
        l_date_short_format     := upper(pk_sysconfig.get_config('DATE_MONTH_DAY', i_prof));
        l_tbl_date_short_format := pk_string_utils.str_split(i_list => l_date_short_format, i_delim => '-');
        pk_alertlog.log_debug('get_iterative_date');
        --
        g_tab_reg_date.delete;
        g_tab_reg_date := get_iterative_date(i_lang,
                                             NULL,
                                             i_begin_date,
                                             i_total_column_number_left,
                                             i_total_column_number_right,
                                             i_patient,
                                             i_id_tl_scale);
        --
        pk_alertlog.log_debug('o_cursor_out');
        OPEN o_cursor_out FOR
        --RIGHT
            SELECT pk_message.get_message(i_lang, 'TL_MONTH') ||
                   /*pk_message.get_message(i_lang,
                                          'TL_MONTH_' || to_number(to_char(scale.dt_end, g_format_mask_short_month))) || ' ' ||
                   lpad(to_char(scale.dt_end, g_format_mask_year), 4, '0')*/
                    get_date_string_month(i_lang     => i_lang,
                                          i_dt_param => l_tbl_date_format,
                                          i_dt_begin => scale.dt_begin,
                                          i_dt_end   => scale.dt_end,
                                          i_format   => 'LONG') BLOCK,
                   ----------------------------BLOCK
                   to_char(scale.dt_begin, g_format_mask_short_day) upper_axis,
                   -----------------------------upper_axis
                   get_date_string_month(i_lang     => i_lang,
                                         i_dt_param => l_tbl_date_format,
                                         i_dt_begin => scale.dt_begin,
                                         i_dt_end   => scale.dt_end,
                                         i_format   => 'SHORT') lower_axis,
                   -----------------------lower_axis
                   to_char(scale.dt_begin, pk_alert_constant.g_date_hour_send_format) dt_begin,
                   ------------------------dt_begin
                   to_char(scale.dt_end, pk_alert_constant.g_date_hour_send_format) dt_end,
                   ----------------------dt_end
                   --scale.actual_date,
                   scale.dt_begin_tzh dt_begin_tzh
              FROM (TABLE(g_tab_reg_date)) scale
             ORDER BY decode(i_total_column_number_right,
                             0,
                             -1 * to_number(to_char(scale.actual_date, 'J')),
                             to_number(to_char(scale.actual_date, 'J'))) ASC,
                      scale.dt_begin ASC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MONTH_CURSOR',
                                              o_error);
            pk_types.open_my_cursor(o_cursor_out);
            RETURN FALSE;
        
    END;

    /*******************************************************************************************************************************************
    * Nome :                          GET_WEEK_CURSOR                                                                                          *
    * Descrição:  WEEK cursor                                                                                                                  *
    *                                                                                                                                          *
    * @param I_LANG                   ID Language                                                                                              *
    * @param I_TOTAL_COLUMN_NUMBER_RIGHTTotal number of columns that must be send to the right side of  the screen                             *
    * @param I_TOTAL_COLUMN_NUMBER_LEFTTotal number of columns thet must be send to the left side ofthe screen                                 *
    * @param I_PATIENT                ID patient                                                                                               *
    * @param I_BEGIN_DATE             Reference date                                                                                                  *
    * @param I_ID_TL_SCALE            ID scale                                                                                                 *
    * @param O_CURSOR_OUT             Output cursor                                                                                            *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    * @return                         WEEK cursor                                                                                              *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_week_cursor
    (
        i_lang                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_total_column_number_right IN NUMBER,
        i_total_column_number_left  IN NUMBER,
        i_patient                   IN NUMBER,
        i_begin_date                IN DATE,
        i_id_tl_scale               IN NUMBER,
        o_cursor_out                OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error           VARCHAR2(4000);
        l_date_format     sys_config.value%TYPE := NULL;
        l_tbl_date_format table_varchar := table_varchar();
    
        l_date_short_format     sys_config.value%TYPE := NULL;
        l_tbl_date_short_format table_varchar := table_varchar();
    BEGIN
    
        g_error           := 'Error fetching DATE_FORMAT sys_config';
        l_date_format     := upper(pk_sysconfig.get_config('DATE_FORMAT', i_prof));
        l_tbl_date_format := pk_string_utils.str_split(i_list => l_date_format, i_delim => '-');
    
        g_error                 := 'Error fetching DATE_MONTH_DAY sys_config';
        l_date_short_format     := upper(pk_sysconfig.get_config('DATE_MONTH_DAY', i_prof));
        l_tbl_date_short_format := pk_string_utils.str_split(i_list => l_date_short_format, i_delim => '-');
    
        IF l_tbl_date_short_format.count = 1
        THEN
            --There are records in sys_config with the ' ' instead of '-'s
            l_tbl_date_short_format := pk_string_utils.str_split(i_list => l_date_short_format, i_delim => ' ');
        END IF;
    
        pk_alertlog.log_debug('get_iterative_date');
        --
        g_tab_reg_date.delete;
        g_tab_reg_date := get_iterative_date(i_lang,
                                             i_prof,
                                             i_begin_date,
                                             i_total_column_number_left,
                                             i_total_column_number_right,
                                             i_patient,
                                             i_id_tl_scale);
        --
        pk_alertlog.log_debug('o_cursor_out');
    
        OPEN o_cursor_out FOR
            SELECT pk_message.get_message(i_lang, 'TL_WEEK') ||
                   get_date_string_week(i_lang     => i_lang,
                                        i_dt_param => l_tbl_date_format,
                                        i_dt_begin => scale.dt_begin,
                                        i_dt_end   => scale.dt_end,
                                        i_format   => 'LONG') BLOCK,
                   ----------------------------BLOCK
                   pk_message.get_message(i_lang, 'TL_WEEK_' || pk_date_utils.week_day_standard(scale.actual_date)) || ' ' ||
                   lpad(to_char(scale.actual_date, g_format_mask_short_day), 2, '0') upper_axis,
                   -----------------------------upper_axis
                   get_date_string_week(i_lang     => i_lang,
                                        i_dt_param => l_tbl_date_short_format,
                                        i_dt_begin => scale.dt_begin,
                                        i_dt_end   => scale.dt_end,
                                        i_format   => 'SHORT') lower_axis,
                   -----------------------lower_axis
                   to_char(scale.actual_date, pk_alert_constant.g_date_hour_send_format) dt_begin,
                   ------------------------dt_begin
                   to_char(scale.actual_date + 1 - INTERVAL '1' SECOND, pk_alert_constant.g_date_hour_send_format) dt_end,
                   ----------------------dt_end
                   --actual_date actual_day
                   scale.dt_begin_tzh dt_begin_tzh
              FROM (TABLE(g_tab_reg_date)) scale
             ORDER BY decode(i_total_column_number_right,
                             0,
                             -1 * to_number(to_char(scale.dt_begin, 'J')),
                             to_number(to_char(scale.actual_date, 'J'))) ASC,
                      
                      scale.actual_date ASC;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WEEK_CURSOR',
                                              o_error);
            pk_types.open_my_cursor(o_cursor_out);
            RETURN FALSE;
        
    END;

    /*******************************************************************************************************************************************
    * Nome :                          GET_DAY_CURSOR                                                                                          *
    * Descrição:  DAY cursor                                                                                                                  *
    *                                                                                                                                          *
    * @param I_LANG                   ID Language                                                                                              *
    * @param I_TOTAL_COLUMN_NUMBER_RIGHTTotal number of columns that must be send to the right side of  the screen                             *
    * @param I_TOTAL_COLUMN_NUMBER_LEFTTotal number of columns thet must be send to the left side ofthe screen                                 *
    * @param I_PATIENT                ID patient                                                                                               *
    * @param I_BEGIN_DATE             Reference date                                                                                                  *
    * @param I_ID_TL_SCALE            ID scale                                                                                                 *
    * @param O_CURSOR_OUT             Output cursor                                                                                            *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         DAY cursor                                                                                              *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/28                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_day_cursor
    (
        i_lang                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_total_column_number_right IN NUMBER,
        i_total_column_number_left  IN NUMBER,
        i_patient                   IN NUMBER,
        i_begin_date                IN DATE,
        i_id_tl_scale               IN NUMBER,
        o_cursor_out                OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error VARCHAR2(4000);
    
        l_date_format     sys_config.value%TYPE := NULL;
        l_tbl_date_format table_varchar := table_varchar();
    
        l_date_short_format     sys_config.value%TYPE := NULL;
        l_tbl_date_short_format table_varchar := table_varchar();
    
    BEGIN
        g_error           := 'Error fetching DATE_FORMAT sys_config';
        l_date_format     := upper(pk_sysconfig.get_config('DATE_FORMAT', i_prof));
        l_tbl_date_format := pk_string_utils.str_split(i_list => l_date_format, i_delim => '-');
    
        g_error                 := 'Error fetching DATE_MONTH_DAY sys_config';
        l_date_short_format     := upper(pk_sysconfig.get_config('DATE_MONTH_DAY', i_prof));
        l_tbl_date_short_format := pk_string_utils.str_split(i_list => l_date_short_format, i_delim => '-');
    
        IF l_tbl_date_short_format.count = 1
        THEN
            --There are records in sys_config with the ' ' instead of '-'s
            l_tbl_date_short_format := pk_string_utils.str_split(i_list => l_date_short_format, i_delim => ' ');
        END IF;
    
        g_error := NULL;
        pk_alertlog.log_debug('get_iterative_date');
        --
        g_tab_reg_date.delete;
        g_tab_reg_date := get_iterative_date(i_lang,
                                             NULL,
                                             i_begin_date,
                                             i_total_column_number_left,
                                             i_total_column_number_right,
                                             i_patient,
                                             i_id_tl_scale);
        --
        pk_alertlog.log_debug('o_cursor_out');
    
        OPEN o_cursor_out FOR
            SELECT pk_message.get_message(i_lang, 'TL_DAY') ||
                   get_date_string(i_lang, l_tbl_date_format(1), scale.dt_begin, NULL, 'LONG') || ' ' ||
                   get_date_string(i_lang, l_tbl_date_format(2), scale.dt_begin, NULL, 'LONG') || ' ' ||
                   get_date_string(i_lang, l_tbl_date_format(3), scale.dt_begin, NULL, 'LONG') BLOCK,
                   ----------------------------BLOCK
                   lpad(to_char(scale.actual_date, g_format_mask_short_hour), 2, '0') upper_axis,
                   -----------------------------upper_axis             
                   get_date_string(i_lang, l_tbl_date_short_format(1), scale.dt_begin, NULL, 'SHORT') || ' ' ||
                   get_date_string(i_lang, l_tbl_date_short_format(2), scale.dt_begin, NULL, 'SHORT') lower_axis,
                   -----------------------lower_axis
                   to_char(scale.dt_begin, pk_alert_constant.g_date_hour_send_format) dt_begin,
                   ------------------------dt_begin
                   to_char(scale.dt_end, pk_alert_constant.g_date_hour_send_format) dt_end,
                   ----------------------dt_end
                   --scale.dt_begin actual_day,
                   scale.dt_begin_tzh
              FROM (TABLE(g_tab_reg_date)) scale
             ORDER BY decode(i_total_column_number_right,
                             0,
                             -1 * to_number(to_char(scale.actual_date, 'J')),
                             to_number(to_char(scale.actual_date, 'J'))) ASC,
                      scale.dt_begin ASC;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DAY_CURSOR',
                                              o_error);
            pk_types.open_my_cursor(o_cursor_out);
            RETURN FALSE;
        
    END;

    FUNCTION get_date_string
    (
        i_lang     IN VARCHAR2,
        i_dt_param IN VARCHAR2,
        i_dt_begin IN DATE,
        i_dt_end   IN DATE DEFAULT NULL,
        i_format   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_message VARCHAR2(1000) := NULL;
    
    BEGIN
        IF upper(i_dt_param) LIKE '%Y%'
        THEN
            l_message := to_char(to_number(to_char(i_dt_begin, g_format_mask_year)));
        
        ELSIF upper(i_dt_param) LIKE '%M%'
              AND i_dt_end IS NOT NULL
        THEN
        
            IF to_char(i_dt_end, g_format_mask_short_month) <> to_char(i_dt_begin, g_format_mask_short_month)
            THEN
            
                l_message := pk_message.get_message(i_lang,
                                                    'TL_MONTH_' ||
                                                    to_number(to_char(i_dt_begin, g_format_mask_short_month)));
            END IF;
        
        ELSIF upper(i_dt_param) LIKE '%M%'
        THEN
            l_message := pk_message.get_message(i_lang,
                                                CASE
                                                    WHEN i_format = 'SHORT' THEN
                                                     'TL_MON_' || to_number(to_char(i_dt_begin, g_format_mask_short_month))
                                                    ELSE
                                                     'TL_MONTH_' || to_number(to_char(i_dt_begin, g_format_mask_short_month))
                                                END);
        ELSIF upper(i_dt_param) LIKE '%D%'
              AND i_dt_end IS NULL
        THEN
            l_message := to_char(i_dt_begin, g_format_mask_short_day);
        ELSIF upper(i_dt_param) LIKE '%D%'
        THEN
            l_message := to_char(i_dt_begin, g_format_mask_short_day);
        
            IF to_char(i_dt_end, g_format_mask_short_month) <> to_char(i_dt_begin, g_format_mask_short_month)
            THEN
                l_message := l_message || ' ' ||
                             pk_message.get_message(i_lang,
                                                    'TL_MONTH_' ||
                                                    to_number(to_char(i_dt_begin, g_format_mask_short_month))) || '-' ||
                             to_char(i_dt_end, g_format_mask_short_day);
            END IF;
        ELSE
            l_message := NULL;
        END IF;
    
        RETURN l_message;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_message;
        
    END get_date_string;

    FUNCTION get_date_string_week
    (
        i_lang     IN VARCHAR2,
        i_dt_param IN table_varchar,
        i_dt_begin IN DATE,
        i_dt_end   IN DATE DEFAULT NULL,
        i_format   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_message VARCHAR2(1000) := NULL;
    
        l_begin_day   VARCHAR2(20) := to_char(i_dt_begin, g_format_mask_short_day);
        l_end_day     VARCHAR2(20) := to_char(i_dt_end, g_format_mask_short_day);
        l_begin_month VARCHAR2(20) := to_char(i_dt_begin, g_format_mask_short_month);
        l_end_month   VARCHAR2(20) := to_char(i_dt_end, g_format_mask_short_month);
        l_begin_year  VARCHAR2(20) := to_char(i_dt_begin, g_format_mask_year);
        l_end_year    VARCHAR2(20) := to_char(i_dt_end, g_format_mask_year);
    
        l_flg_day   BOOLEAN := FALSE;
        l_flg_month BOOLEAN := FALSE;
        l_flg_year  BOOLEAN := FALSE;
    
        l_month_format VARCHAR2(10) := NULL;
    
    BEGIN
    
        IF i_format = 'LONG'
        THEN
            l_month_format := 'TL_MONTH_';
        ELSIF i_format = 'SHORT'
        THEN
            l_month_format := 'TL_MON_';
        END IF;
    
        FOR i IN i_dt_param.first .. i_dt_param.last
        LOOP
            IF l_begin_month = l_end_month
            THEN
                IF upper(i_dt_param(i)) LIKE '%Y%'
                THEN
                    l_message := l_message || to_char(to_number(to_char(i_dt_begin, g_format_mask_year))) || ' ';
                
                ELSIF upper(i_dt_param(i)) LIKE '%M%'
                THEN
                    l_message := l_message ||
                                 pk_message.get_message(i_lang,
                                                        l_month_format ||
                                                        to_number(to_char(i_dt_begin, g_format_mask_short_month))) || ' ';
                ELSIF upper(i_dt_param(i)) LIKE '%D%'
                THEN
                    l_message := l_message || to_char(i_dt_begin, g_format_mask_short_day) || '-' ||
                                 to_char(i_dt_end, g_format_mask_short_day) || ' ';
                ELSE
                    l_message := NULL;
                END IF;
            ELSE
                IF upper(i_dt_param(i)) LIKE '%Y%'
                THEN
                    l_message := l_message || to_char(to_number(to_char(i_dt_begin, g_format_mask_year))) || ' ';
                    IF l_begin_year <> l_end_year
                    THEN
                        l_flg_year := TRUE;
                    END IF;
                ELSIF upper(i_dt_param(i)) LIKE '%M%'
                THEN
                    l_message   := l_message ||
                                   pk_message.get_message(i_lang,
                                                          l_month_format ||
                                                          to_number(to_char(i_dt_begin, g_format_mask_short_month))) || ' ';
                    l_flg_month := TRUE;
                ELSIF upper(i_dt_param(i)) LIKE '%D%'
                THEN
                    l_message := l_message || to_char(i_dt_begin, g_format_mask_short_day) || ' ';
                    l_flg_day := TRUE;
                ELSE
                    l_message := NULL;
                END IF;
            
                IF l_flg_day = TRUE
                   AND l_flg_month = TRUE
                   AND l_begin_year = l_end_year
                THEN
                
                    l_flg_day   := FALSE;
                    l_flg_month := FALSE;
                    l_flg_year  := FALSE;
                
                    l_message := l_message || '- ';
                
                    FOR j IN i_dt_param.first .. i_dt_param.last
                    LOOP
                        IF upper(i_dt_param(j)) LIKE '%M%'
                        THEN
                            l_message := l_message ||
                                         pk_message.get_message(i_lang,
                                                                l_month_format ||
                                                                to_number(to_char(i_dt_end, g_format_mask_short_month))) || ' ';
                        ELSIF upper(i_dt_param(j)) LIKE '%D%'
                        THEN
                            l_message := l_message || to_char(i_dt_end, g_format_mask_short_day) || ' ';
                        END IF;
                    END LOOP;
                ELSIF l_flg_day = TRUE
                      AND l_flg_month = TRUE
                      AND (l_flg_year = TRUE OR i_format = 'SHORT')
                THEN
                    l_flg_day   := FALSE;
                    l_flg_month := FALSE;
                    l_flg_year  := FALSE;
                
                    l_message := l_message || '- ';
                
                    FOR j IN i_dt_param.first .. i_dt_param.last
                    LOOP
                        IF upper(i_dt_param(j)) LIKE '%M%'
                        THEN
                            l_message := l_message ||
                                         pk_message.get_message(i_lang,
                                                                l_month_format ||
                                                                to_number(to_char(i_dt_end, g_format_mask_short_month))) || ' ';
                        ELSIF upper(i_dt_param(j)) LIKE '%D%'
                        THEN
                            l_message := l_message || to_char(i_dt_end, g_format_mask_short_day) || ' ';
                        
                        ELSIF upper(i_dt_param(j)) LIKE '%Y%'
                        THEN
                            l_message := l_message || to_char(to_number(to_char(i_dt_end, g_format_mask_year))) || ' ';
                        END IF;
                    
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    
        RETURN l_message;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_message;
        
    END get_date_string_week;

    FUNCTION get_date_string_month
    (
        i_lang     IN VARCHAR2,
        i_dt_param IN table_varchar,
        i_dt_begin IN DATE,
        i_dt_end   IN DATE DEFAULT NULL,
        i_format   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_message VARCHAR2(1000) := NULL;
    
        l_month_format VARCHAR2(10);
    
    BEGIN
    
        IF i_format = 'LONG'
        THEN
            l_month_format := 'TL_MONTH_';
        ELSIF i_format = 'SHORT'
        THEN
            l_month_format := 'TL_MON_';
        END IF;
    
        FOR i IN i_dt_param.first .. i_dt_param.last
        LOOP
            IF upper(i_dt_param(i)) LIKE '%Y%'
            THEN
                l_message := l_message || to_char(to_number(to_char(i_dt_end, g_format_mask_year))) || ' ';
            
            ELSIF upper(i_dt_param(i)) LIKE '%M%'
            THEN
            
                l_message := l_message ||
                             pk_message.get_message(i_lang,
                                                    l_month_format ||
                                                    to_number(to_char(i_dt_end, g_format_mask_short_month))) || ' ';
            END IF;
        END LOOP;
    
        RETURN l_message;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_message;
        
    END get_date_string_month;

    /*******************************************************************************************************************************************
    * Nome :                          GET_SHIFT_CURSOR                                                                                          *
    * Descrição:                      Function that returns information about shifts when selected time frame is Shift (6h, 8h, 10h and 12h)
    *                                                                                                                                          *
    * @param I_LANG                   ID Language
    * @param I_TOTAL_COLUMN_NUMBER_RIGHT Total number of columns that must be send to the right side of  the screen
    * @param I_TOTAL_COLUMN_NUMBER_LEFT Total number of columns thet must be send to the left side ofthe screen
    * @param I_PATIENT                ID patient
    * @param I_BEGIN_DATE             Reference date
    * @param I_ID_TL_SCALE            ID scale
    * @param O_CURSOR_OUT             Output cursor
    * @param O_ERROR                  Output error
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         SHIFT cursor
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Luís Maia
    * @version                         1.0
    * @since                          2009/03/26
    *******************************************************************************************************************************************/
    FUNCTION get_shift_cursor
    (
        i_lang                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_total_column_number_right IN NUMBER,
        i_total_column_number_left  IN NUMBER,
        i_patient                   IN NUMBER,
        i_begin_date                IN DATE,
        i_id_tl_scale               IN NUMBER,
        o_cursor_out                OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error               VARCHAR2(4000);
        l_function_name       VARCHAR2(200) := 'GET_SHIFT_CURSOR';
        l_inst_shift_duration NUMBER;
        shift_duration_exception EXCEPTION;
        l_tl_scale_description VARCHAR2(4000);
    BEGIN
    
        -- Get shift duration to current institution
        pk_alertlog.log_debug('GET institution shift duration');
        l_inst_shift_duration := pk_sysconfig.get_config('TIMELINE_CARDEX_SHIFT_DURATION', i_prof);
        IF l_inst_shift_duration IS NULL
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE_SHIFT_DURATION');
            RAISE shift_duration_exception;
        END IF;
        l_tl_scale_description := REPLACE(pk_translation.get_translation(i_lang, 'TL_SCALE.CODE_SCALE.7'),
                                          '@1',
                                          l_inst_shift_duration);
    
        pk_alertlog.log_debug('get_iterative_date');
        --
        g_tab_reg_date.delete;
        g_tab_reg_date := get_iterative_date(i_lang,
                                             i_prof,
                                             i_begin_date,
                                             i_total_column_number_left,
                                             i_total_column_number_right,
                                             i_patient,
                                             i_id_tl_scale);
        --
        pk_alertlog.log_debug('o_cursor_out');
        IF i_total_column_number_right = 0
        THEN
            --
            OPEN o_cursor_out FOR
                SELECT pk_message.get_message(i_lang, 'TL_SHIFT') || --
                       ' (' || l_tl_scale_description || '):' || --
                       to_char(scale.dt_begin, g_format_mask_short_day) || ' ' || --
                       pk_message.get_message(i_lang,
                                              'TL_MONTH_' ||
                                              to_number(to_char(scale.dt_begin, g_format_mask_short_month))) || ' ' ||
                       to_number(to_char(scale.dt_end, g_format_mask_year)) BLOCK,
                       ----------------------------BLOCK
                       lpad(to_char(scale.actual_date, g_format_mask_short_hour), 2, '0') || 'h' upper_axis,
                       -----------------------------upper_axis
                       lpad(to_char(scale.dt_begin, g_format_mask_short_hour), 2, '0') || --
                       'h-' || --
                       decode(lpad(to_char((scale.dt_begin + (l_inst_shift_duration / g_daily_hours)),
                                           g_format_mask_short_hour),
                                   2,
                                   '0'),
                              '00',
                              '24h',
                              lpad(to_char((scale.dt_begin + (l_inst_shift_duration / g_daily_hours)),
                                           g_format_mask_short_hour),
                                   2,
                                   '0') || 'h') lower_axis,
                       -----------------------lower_axis
                       to_char(scale.dt_begin, pk_alert_constant.g_date_hour_send_format) dt_begin,
                       ------------------------dt_begin
                       to_char(scale.dt_end, pk_alert_constant.g_date_hour_send_format) dt_end,
                       ----------------------dt_end
                       --scale.dt_begin     actual_day,
                       scale.dt_begin_tzh dt_begin_tzh
                  FROM (TABLE(g_tab_reg_date)) scale
                 ORDER BY decode(i_total_column_number_right,
                                 0,
                                 -1 * to_number(to_char(scale.actual_date, 'J')),
                                 to_number(to_char(scale.actual_date, 'J'))) ASC,
                          scale.dt_begin DESC;
        ELSE
            --
            OPEN o_cursor_out FOR
                SELECT pk_message.get_message(i_lang, 'TL_SHIFT') || --
                       ' (' || l_tl_scale_description || '):' || --
                       to_char(scale.dt_begin, g_format_mask_short_day) || ' ' || --
                       pk_message.get_message(i_lang,
                                              'TL_MONTH_' ||
                                              to_number(to_char(scale.dt_begin, g_format_mask_short_month))) || ' ' ||
                       to_number(to_char(scale.dt_end, g_format_mask_year)) BLOCK,
                       ----------------------------BLOCK
                       lpad(to_char(scale.actual_date, g_format_mask_short_hour), 2, '0') || 'h' upper_axis,
                       -----------------------------upper_axis
                       lpad(to_char(scale.dt_begin, g_format_mask_short_hour), 2, '0') || --
                       'h-' || --
                       decode(lpad(to_char((scale.dt_begin + (l_inst_shift_duration / g_daily_hours)),
                                           g_format_mask_short_hour),
                                   2,
                                   '0'),
                              '00',
                              '24h',
                              lpad(to_char((scale.dt_begin + (l_inst_shift_duration / g_daily_hours)),
                                           g_format_mask_short_hour),
                                   2,
                                   '0') || 'h') lower_axis,
                       -----------------------lower_axis
                       to_char(scale.dt_begin, pk_alert_constant.g_date_hour_send_format) dt_begin,
                       ------------------------dt_begin
                       to_char(scale.dt_end, pk_alert_constant.g_date_hour_send_format) dt_end,
                       ----------------------dt_end
                       --scale.dt_begin     actual_day,
                       scale.dt_begin_tzh dt_begin_tzh
                  FROM (TABLE(g_tab_reg_date)) scale
                 ORDER BY decode(i_total_column_number_right,
                                 0,
                                 -1 * to_number(to_char(scale.actual_date, 'J')),
                                 to_number(to_char(scale.actual_date, 'J'))) ASC,
                          scale.dt_begin ASC;
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN shift_duration_exception THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000);
            BEGIN
                l_error_message := pk_message.get_message(i_lang, g_general_error);
                l_error_in.set_all(i_lang,
                                   'ERROR_SHIFT_DURATION_NOT_DEFINED',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
                pk_utils.undo_changes;
                l_error_in.set_action(l_error_message, 'U');
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                --
                pk_types.open_my_cursor(o_cursor_out);
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_cursor_out);
            RETURN FALSE;
    END get_shift_cursor;

    /*******************************************************************************************************************************************
    * Nome :                          GET_TIMELINE_DATA                                                                                        *
    * Descrição:  Função que devolve as diferentes escalas horizontais para preenchimento da timeline e respectivos episodios                  *
    *                                                                                                                                          *
    * @param I_LANG                   ID da linguagem para traduções                                                                           *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param ID_TL_TIMELINE           ID da TIMELINE                                                                                           *
    * @param ID_TL_SCALE              ID da ESCALA                                                                                             *
    * @param I_BLOCK_REQ_NUMBER       Número de blocos de informação pedidos                                                                   *
    * @param I_REQUEST_DATE           Data a partir da qual é pedida a informação                                                              *
    * @param I_DIRECTION              Direcção para onde devem ser contados os blocos de tempo a devolver                                      *
    * @param I_PATIENT                ID do paciente                                                                                           *
    * @param O_X_data                 Cursor que devolve os titulos dos blocos expl: Década 1990                                               *
    * @param O_episode                Cursor que devolve os episodios                                               *
    * @param O_ERROR                  Devolução do erro                                                                                        *
    *                                                                                                                                          *
    * @value I_DIRECTION              R-RIGHT, L-LEFT, B-BOTH                                                                                  *
    *                                                                                                                                          *
    * @return                         Devolve false em caso de erro e true caso contrário                                                      *
    * @raises                         Erro genérico de oracle                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/16                                                                                               *
    *******************************************************************************************************************************************/

    FUNCTION get_timeline_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        id_tl_timeline     IN tl_timeline.id_tl_timeline%TYPE,
        id_tl_scale        IN tl_scale.id_tl_scale%TYPE,
        i_block_req_number IN NUMBER,
        i_request_date     IN VARCHAR2,
        i_direction        IN VARCHAR2 DEFAULT 'B',
        i_patient          IN NUMBER,
        o_x_data           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function                  VARCHAR2(200) := 'GET_TIMELINE_DATA';
        l_return                    BOOLEAN := TRUE;
        g_error                     VARCHAR2(4000);
        l_total_column_number_right NUMBER(24);
        l_total_column_number_left  NUMBER(24);
        l_begin_date                DATE;
        l_direction                 VARCHAR2(10) := 'RIGHT';
    
        l_request_date VARCHAR2(400) := to_char(pk_date_utils.get_timestamp_insttimezone(NULL, i_prof.institution),
                                                pk_alert_constant.g_date_hour_send_format);
    
        user_exception EXCEPTION;
    BEGIN
        --pk_types.open_my_cursor(o_x_data);
    
        IF i_prof.id IS NULL
           OR i_prof.institution IS NULL
           OR i_prof.software IS NULL
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M038');
            g_error := REPLACE(g_error || ' (i_prof)', '@1', 'get_timeline_data');
            RAISE user_exception;
        END IF;
    
        --initialize retirar apos ser chamado do flash
        pk_alertlog.log_debug('initialize');
        IF NOT initialize(i_lang, i_prof, o_error)
        THEN
            g_error := pk_message.get_message(i_lang, 'TL_INITIALIZE');
            RAISE user_exception;
        END IF;
    
        -- Column number
        pk_alertlog.log_debug('pk_date_utils.get_string_tstz');
        IF i_direction = 'R'
        THEN
            l_direction := 'RIGHT';
        ELSIF i_direction = 'L'
        THEN
            l_direction := 'LEFT';
        ELSIF i_direction = 'B'
        THEN
            l_direction := 'RIGHT';
        END IF;
    
        -- Begin date
        pk_alertlog.log_debug('truncate_date_to_begin_block');
        l_begin_date := truncate_date_to_begin_block(i_lang,
                                                     i_prof,
                                                     id_tl_timeline,
                                                     id_tl_scale,
                                                     l_direction,
                                                     nvl(i_request_date, l_request_date),
                                                     o_error);
        pk_alertlog.log_debug('pk_date_utils.get_string_tstz');
    
        IF i_direction = 'R'
        THEN
            l_direction                 := 'RIGHT';
            l_total_column_number_right := get_total_columns(i_lang,
                                                             i_prof,
                                                             id_tl_timeline,
                                                             i_block_req_number,
                                                             id_tl_scale,
                                                             l_direction,
                                                             l_begin_date,
                                                             o_error);
            l_total_column_number_left  := 0;
        ELSIF i_direction = 'L'
        THEN
            l_direction                 := 'LEFT';
            l_total_column_number_right := 0;
            l_total_column_number_left  := get_total_columns(i_lang,
                                                             i_prof,
                                                             id_tl_timeline,
                                                             i_block_req_number,
                                                             id_tl_scale,
                                                             l_direction,
                                                             l_begin_date,
                                                             o_error);
        
            -- It is necessary remove left column from time scales that are not devided in hours (unit measure)
            IF (id_tl_scale != pk_alert_constant.g_day AND id_tl_scale != pk_alert_constant.g_shift)
            THEN
                l_total_column_number_left := l_total_column_number_left - 1;
            END IF;
        
        ELSIF i_direction = 'B'
        THEN
            l_total_column_number_right := get_total_columns(i_lang,
                                                             i_prof,
                                                             id_tl_timeline,
                                                             ceil(i_block_req_number / 2),
                                                             id_tl_scale,
                                                             'RIGHT',
                                                             l_begin_date,
                                                             o_error);
            l_total_column_number_left  := get_total_columns(i_lang,
                                                             i_prof,
                                                             id_tl_timeline,
                                                             ceil(i_block_req_number / 2),
                                                             id_tl_scale,
                                                             'LEFT',
                                                             l_begin_date,
                                                             o_error);
        END IF;
    
        -- OUTPUT ARRAY
        pk_alertlog.log_debug('pk_date_utils.get_string_tstz');
        -- DÉCADE
        IF id_tl_scale = pk_alert_constant.g_decade
        THEN
            pk_alertlog.log_debug('get_decade_cursor');
            IF NOT get_decade_cursor(i_lang,
                                     l_total_column_number_right,
                                     l_total_column_number_left,
                                     i_patient,
                                     l_begin_date,
                                     id_tl_scale,
                                     o_x_data,
                                     o_error)
            THEN
                RAISE user_exception;
            END IF;
            -- YEAR
        ELSIF id_tl_scale = pk_alert_constant.g_year
        THEN
            pk_alertlog.log_debug('get_year_cursor');
            IF NOT get_year_cursor(i_lang,
                                   l_total_column_number_right,
                                   l_total_column_number_left,
                                   i_patient,
                                   l_begin_date,
                                   id_tl_scale,
                                   o_x_data,
                                   o_error)
            THEN
                RAISE user_exception;
            END IF; --MONTH
        ELSIF id_tl_scale = pk_alert_constant.g_month
        THEN
        
            pk_alertlog.log_debug('get_month_cursor');
            IF NOT get_month_cursor(i_lang,
                                    i_prof,
                                    l_total_column_number_right,
                                    l_total_column_number_left,
                                    i_patient,
                                    l_begin_date,
                                    id_tl_scale,
                                    o_x_data,
                                    o_error)
            THEN
                RAISE user_exception;
            END IF; --WEEK
        ELSIF id_tl_scale = pk_alert_constant.g_week
        THEN
            pk_alertlog.log_debug('get_week_cursor');
            IF NOT get_week_cursor(i_lang                      => i_lang,
                                   i_prof                      => i_prof,
                                   i_total_column_number_right => l_total_column_number_right,
                                   i_total_column_number_left  => l_total_column_number_left,
                                   i_patient                   => i_patient,
                                   i_begin_date                => l_begin_date,
                                   i_id_tl_scale               => id_tl_scale,
                                   o_cursor_out                => o_x_data,
                                   o_error                     => o_error)
            THEN
                RAISE user_exception;
            END IF;
            --DAY
        ELSIF id_tl_scale = pk_alert_constant.g_day
        THEN
            pk_alertlog.log_debug('get_day_cursor');
            IF NOT get_day_cursor(i_lang,
                                  i_prof,
                                  l_total_column_number_right,
                                  l_total_column_number_left,
                                  i_patient,
                                  l_begin_date,
                                  id_tl_scale,
                                  o_x_data,
                                  o_error)
            THEN
                RAISE user_exception;
            END IF;
            --Shift
        ELSIF id_tl_scale = pk_alert_constant.g_shift
        THEN
            pk_alertlog.log_debug('get_shift_cursor');
            IF NOT get_shift_cursor(i_lang,
                                    i_prof,
                                    l_total_column_number_right,
                                    l_total_column_number_left,
                                    i_patient,
                                    l_begin_date,
                                    id_tl_scale,
                                    o_x_data,
                                    o_error)
            THEN
                RAISE user_exception;
            END IF;
        
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function,
                                              'U',
                                              o_error);
            pk_types.open_my_cursor(o_x_data);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function,
                                              o_error);
            pk_types.open_my_cursor(o_x_data);
            RETURN FALSE;
        
    END;

    FUNCTION get_timescale_by_tl
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_scale_inst_soft_market.id_tl_timeline%TYPE,
        o_tl_scales      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function VARCHAR2(200) := 'GET_TIMESCALE_BY_TL';
    
    BEGIN
    
        OPEN o_tl_scales FOR
            SELECT t.id_tl_scale_xupper,
                   pk_translation.get_translation(i_lang, 'TL_SCALE.CODE_SCALE.' || t.id_tl_scale_xupper) label_scale_upper,
                   t.id_tl_scale_xlower,
                   pk_translation.get_translation(i_lang, 'TL_SCALE.CODE_SCALE.' || t.id_tl_scale_xlower) label_scale_lower,
                   t.flg_default
              FROM (SELECT tls.id_tl_scale_xupper,
                           tls.id_tl_scale_xlower,
                           tls.flg_default,
                           tls.rank,
                           row_number() over(PARTITION BY tls.id_tl_scale_xupper ORDER BY tls.id_institution DESC, tls.id_software DESC) rn
                      FROM tl_scale_inst_soft_market tls
                     WHERE tls.id_tl_timeline = i_id_tl_timeline
                       AND tls.id_institution IN (i_prof.institution, 0)
                       AND tls.id_software IN (i_prof.software, 0)
                       AND tls.flg_available = pk_alert_constant.g_yes) t
             WHERE t.rn = 1
             ORDER BY t.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function,
                                              o_error);
            pk_types.open_my_cursor(o_tl_scales);
            RETURN FALSE;
        
    END get_timescale_by_tl;
BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    --default timezone
    g_tl_timezone := 'Europe/Lisbon';

END pk_timeline_core;
/
