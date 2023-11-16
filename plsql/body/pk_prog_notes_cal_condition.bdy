CREATE OR REPLACE PACKAGE BODY pk_prog_notes_cal_condition IS

    -- Private variable declarations
    g_error         VARCHAR2(1000 CHAR);
    g_package_owner VARCHAR2(30 CHAR) := 'ALERT';
    g_package_name  VARCHAR2(30 CHAR) := 'PK_PROG_NOTES_CAL_CONDITION';
    g_exception EXCEPTION;

    -- Date mask
    g_sd_mask CONSTANT VARCHAR2(10 CHAR) := 'YYYY-MM-DD';
    g_ld_mask CONSTANT VARCHAR2(21 CHAR) := 'YYYY-MM-DD HH24:MI:SS';

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_pn_area                All pn_area number
    * @param i_id_episode             Episode ID
    * @param i_begin_date             Get note list begin date
    * @param i_end_date               Get note list end date
    *
    * @param o_note_lists             cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_all_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pn_area    IN table_number,
        i_id_episode IN episode.id_episode%TYPE,
        i_begin_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_note_lists OUT t_coll_note_type_condition,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(50 CHAR) := 'GET_ALL_NOTE_LIST';
        l_market          market.id_market%TYPE;
        l_id_pn_note_type table_number;
    BEGIN
        g_error := 'Enter get_all_note i_id_episode:' || i_id_episode || ' i_begin_date:' || to_char(i_begin_date) ||
                   ' i_end_date:' || to_char(i_end_date);
        pk_alertlog.log_info(g_error);
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        SELECT DISTINCT epn.id_pn_note_type
          BULK COLLECT
          INTO l_id_pn_note_type
          FROM epis_pn epn
         INNER JOIN episode epi
            ON epi.id_episode = epn.id_episode
         INNER JOIN pn_area pna
            ON epn.id_pn_area = pna.id_pn_area
         WHERE pna.id_pn_area IN (SELECT *
                                    FROM TABLE(i_pn_area))
           AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
           AND epn.id_episode = i_id_episode
           AND epn.dt_pn_date >= i_begin_date
           AND epn.dt_pn_date < i_end_date;
    
        SELECT t_rec_note_type_condition(pntm.id_pn_area,
                                         pntm.id_pn_note_type,
                                         pk_message.get_message(i_lang, i_prof, pnt.code_pn_note_type),
                                         pntm.cal_delay_time,
                                         pntm.cal_icu_delay_time,
                                         pntm.cal_expect_date,
                                         pntm.flg_cal_type,
                                         pntm.flg_cal_time_filter,
                                         pntm.flg_edit_condition)
          BULK COLLECT
          INTO o_note_lists
          FROM pn_note_type_mkt pntm
          JOIN pn_note_type pnt
            ON pnt.id_pn_note_type = pntm.id_pn_note_type
          JOIN (SELECT /*+ OPT_ESTIMATE(TABLE x1 ROWS=1) */
                DISTINCT column_value id_pn_area
                  FROM TABLE(i_pn_area) x1) pa
            ON pa.id_pn_area = pntm.id_pn_area
           AND pntm.id_market = l_market
           AND (pntm.flg_calendar_view = pk_alert_constant.g_yes OR
               ((pntm.flg_calendar_view = pk_alert_constant.get_no OR pntm.flg_calendar_view IS NULL) AND
               pntm.id_pn_note_type IN (SELECT * /*+ OPT_ESTIMATE(TABLE x ROWS=1) */
                                            FROM TABLE(l_id_pn_note_type) x)))
         ORDER BY pntm.rank;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_all_note;

    /**************************************************************************
    * get pn_area list use pn_area internal name
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_internal_name          PN_AREA internal name
    *
    * @param o_pn_area_lists          All PN_AREA ID
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-05                       
    **************************************************************************/
    FUNCTION get_pn_area_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN table_varchar,
        o_pn_area_lists OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(50 CHAR) := 'GET_PN_AREA_LIST';
    BEGIN
        SELECT pa.id_pn_area
          BULK COLLECT
          INTO o_pn_area_lists
          FROM pn_area pa
         WHERE pa.internal_name IN (SELECT *
                                      FROM TABLE(i_internal_name));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pn_area_list;

    /**************************************************************************
    * get dates in specific period
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_bdate                  begin date of period
    * @param i_edate                  begin date of period
    * @param o_dates                  All dates of this period
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-30                       
    **************************************************************************/
    FUNCTION get_dates_of_period
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_bdate IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_edate IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_dates OUT table_timestamp,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(50 CHAR) := 'GET_DATES_OF_PERIOD';
        l_diff      INTERVAL DAY(4) TO SECOND;
        l_diff_num  NUMBER;
    BEGIN
        g_error := 'i_begin_date:' || i_bdate || ' i_end_date:' || i_edate;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_diff     := i_edate - i_bdate;
        l_diff_num := extract(DAY FROM l_diff);
        g_error    := 'l_diff:' || l_diff || ' l_diff_num:' || l_diff_num;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        o_dates := table_timestamp();
        FOR i IN 0 .. l_diff_num
        LOOP
            o_dates.extend;
            o_dates(o_dates.last) := i_bdate + numtodsinterval(i, 'DAY');
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_dates_of_period;

    /**************************************************************************
    * get begin and end date in current week
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_date                   date of this week
    * @param o_bdate                  begin date of this week
    * @param o_edate                  end date of this week
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-30                       
    **************************************************************************/
    FUNCTION get_f_e_date_of_week
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_bdate OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_edate OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_dates OUT table_timestamp,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(20 CHAR) := 'GET_F_E_DATE_OF_WEEK';
        l_fd_format sys_config.value%TYPE;
        l_cal_fd    NUMBER;
        l_bool      BOOLEAN;
    BEGIN
        -- date_format to decide calculate first date of week is Monday or Sunday ex.M or S
        l_cal_fd := get_first_date_of_week(i_prof => i_prof);
    
        o_bdate := CAST(trunc(i_date, 'IW') AS TIMESTAMP WITH LOCAL TIME ZONE) - numtodsinterval(l_cal_fd, 'DAY');
        o_edate := CAST(trunc(i_date, 'IW') AS TIMESTAMP WITH LOCAL TIME ZONE) + numtodsinterval(6 - l_cal_fd, 'DAY');
    
        g_error := 'o_bdate:' || o_bdate || ' o_edate:' || o_edate;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_bool := get_dates_of_period(i_lang  => i_lang,
                                      i_prof  => i_prof,
                                      i_bdate => o_bdate,
                                      i_edate => o_edate,
                                      o_dates => o_dates,
                                      o_error => o_error);
        RETURN l_bool;
    END get_f_e_date_of_week;

    /**************************************************************************
    * get calendar header name of date
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_nls_code               nls code
    * @param i_date                   Calendar every date name
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_name_of_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(050 CHAR) := 'GET_NAME_OF_DATE';
        l_return    VARCHAR2(100 CHAR);
    BEGIN
        g_error := 'i_date:' || i_date || ', i_dt_begin:' || i_dt_begin;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        SELECT pk_date_utils.to_char_insttimezone(i_prof, i_date, 'DD') || pk_prog_notes_constants.g_open_parenthesis ||
               pk_message.get_message(i_lang      => i_lang,
                                      i_prof      => i_prof,
                                      i_code_mess => 'PROG_NOTE_CALENDAR_NAME_OF_WEEK_' ||
                                                     pk_date_utils.to_char_insttimezone(i_prof, i_date, 'D')) ||
               pk_prog_notes_constants.g_close_parenthesis
          INTO l_return
          FROM dual;
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(text            => 'SQLCODE: ' || SQLCODE || 'SQLERRM: ' || SQLERRM,
                                  object_name     => g_package_name,
                                  sub_object_name => l_func_name,
                                  owner           => g_package_owner);
            RETURN l_return;
    END get_name_of_date;

    /**************************************************************************
    * get calendar title period
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_bdate                  begin date of period
    * @param i_edate                  begin date of period
    *
    * @param o_note_lists             cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_period
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_begin_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(050 CHAR) := 'GET_PERIOD';
        l_return    VARCHAR2(100 CHAR);
        l_nls_code  VARCHAR2(050 CHAR);
    BEGIN
    
        SELECT pk_date_utils.to_char_insttimezone(i_prof, i_begin_date, 'YYYY') || pk_prog_notes_constants.g_space ||
               pk_date_utils.to_char_insttimezone(i_prof, i_begin_date, 'Mon') || pk_prog_notes_constants.g_space ||
               pk_date_utils.to_char_insttimezone(i_prof, i_begin_date, 'DD') || pk_prog_notes_constants.g_flg_sep ||
               decode(pk_date_utils.to_char_insttimezone(i_prof, i_begin_date, 'YYYY'),
                      pk_date_utils.to_char_insttimezone(i_prof, i_end_date, 'YYYY'),
                      '',
                      pk_date_utils.to_char_insttimezone(i_prof, i_end_date, 'YYYY') || pk_prog_notes_constants.g_space) ||
               pk_date_utils.to_char_insttimezone(i_prof, i_end_date, 'Mon') || pk_prog_notes_constants.g_space ||
               pk_date_utils.to_char_insttimezone(i_prof, i_end_date, 'DD')
          INTO l_return
          FROM dual;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(text            => 'SQLCODE: ' || SQLCODE || 'SQLERRM: ' || SQLERRM,
                                  object_name     => g_package_name,
                                  sub_object_name => l_func_name,
                                  owner           => g_package_owner);
            RETURN l_return;
    END get_period;
    /**************************************************************************
    * Calculate all expect note with condition
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_pn_note_type        pn_note_type ID
    * @param i_admission_date         This episode admisson date
    * @param i_begin_date             Get expect note begin date
    * @param i_end_date               Get expect note end date
    * @param i_cal_flg_type           To do diffrent calculate
    * @param i_rule_day               To do diffrent calculate
    *
    * @param o_note_expect_note       All expect note
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-16                       
    **************************************************************************/
    FUNCTION calculate_dt
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_area       IN pn_area.id_pn_area%TYPE,
        i_admission_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_discharge_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_begin_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_cal_flg_type     IN VARCHAR2,
        i_rule_day         IN NUMBER,
        o_note_expect_note OUT t_coll_note_type_dt,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tbl_type       t_coll_note_type_dt := t_coll_note_type_dt();
        l_tbl_type_temp  t_coll_note_type_dt := t_coll_note_type_dt();
        l_admission_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_dates_list     table_timestamp;
        l_end_date       TIMESTAMP WITH LOCAL TIME ZONE;
        l_return         BOOLEAN;
        l_func_name      VARCHAR2(50 CHAR) := 'CALCULATE_DT';
        l_num            NUMBER;
    BEGIN
        l_admission_date := pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => i_admission_date);
        g_error          := 'i_admission_date:' || i_admission_date || 'l_admission_date:' || l_admission_date ||
                            ' i_id_pn_note_type:' || i_id_pn_note_type || ' i_cal_flg_type:' || i_cal_flg_type ||
                            'i_rule_day:' || i_rule_day || ' i_begin_date:' || i_begin_date || ' i_end_date:' ||
                            i_end_date;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF i_discharge_date IS NOT NULL
           AND i_discharge_date < i_end_date
        THEN
            l_end_date := i_discharge_date;
        ELSE
            l_end_date := i_end_date;
        END IF;
    
        IF i_rule_day = 1
           AND i_cal_flg_type = g_progress_note
        THEN
            IF NOT get_dates_of_period(i_lang  => i_lang,
                                       i_prof  => i_prof,
                                       i_bdate => l_admission_date,
                                       i_edate => i_end_date,
                                       o_dates => l_dates_list,
                                       o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
            SELECT t_rec_note_type_dt(id_pn_note_type => i_id_pn_note_type,
                                      id_episode      => i_id_episode,
                                      dt_event        => every_day.dt_event)
              BULK COLLECT
              INTO l_tbl_type
              FROM (SELECT /*+ OPT_ESTIMATE(TABLE ldl ROWS=1) */
                     column_value dt_event
                      FROM TABLE(l_dates_list) ldl) every_day
             WHERE every_day.dt_event >= i_begin_date
               AND every_day.dt_event <= l_end_date
               AND every_day.dt_event > i_admission_date;
        
            FOR x IN 1 .. l_dates_list.count
            LOOP
                g_error := 'l_dates_list(x): ' || l_dates_list(x);
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            END LOOP;
        
        END IF;
    
        IF i_rule_day = 7
        THEN
            g_error := 'i_rule_day:' || to_char(i_rule_day);
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            IF NOT get_dates_of_period(i_lang  => i_lang,
                                       i_prof  => i_prof,
                                       i_bdate => l_admission_date,
                                       i_edate => i_end_date,
                                       o_dates => l_dates_list,
                                       o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_num := l_dates_list.count;
            SELECT t_rec_note_type_dt(id_pn_note_type => i_id_pn_note_type,
                                      id_episode      => i_id_episode,
                                      dt_event        => t.dt_event)
              BULK COLLECT
              INTO l_tbl_type
              FROM (SELECT *
                      FROM (SELECT l_admission_date + numtodsinterval(LEVEL * 7, 'DAY') dt_event
                              FROM dual
                            CONNECT BY LEVEL <= l_num / 7) every_sevend
                     WHERE every_sevend.dt_event > i_admission_date
                       AND every_sevend.dt_event >= i_begin_date
                       AND every_sevend.dt_event <= l_end_date) t;
        
        END IF;
    
        -- Base on admission date to calculate purposed date
        IF i_cal_flg_type = g_admission_problem_listing
           AND i_rule_day = 0
        THEN
            l_tbl_type.extend;
            l_tbl_type(l_tbl_type.last) := t_rec_note_type_dt(id_pn_note_type => i_id_pn_note_type,
                                                              id_episode      => i_id_episode,
                                                              dt_event        => i_admission_date);
        END IF;
    
        IF i_cal_flg_type = g_attending_progress_note
        THEN
            l_tbl_type_temp := l_tbl_type;
            SELECT t_rec_note_type_dt(id_pn_note_type => tt.id_pn_note_type,
                                      id_episode      => tt.id_episode,
                                      dt_event        => tt.dt_event)
              BULK COLLECT
              INTO l_tbl_type
              FROM (SELECT at.id_pn_note_type, at.id_episode, at.dt_event
                      FROM (SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=1) */
                             t.dt_event, t.id_pn_note_type, t.id_episode, dt_ho
                              FROM TABLE(l_tbl_type_temp) t
                              LEFT JOIN (SELECT /*+ OPT_ESTIMATE(TABLE gh ROWS=1) */
                                         CAST(column_value AS TIMESTAMP WITH LOCAL TIME ZONE) dt_ho
                                          FROM TABLE(pk_prog_notes_cal_condition.get_holidays(i_prof           => i_prof,
                                                                                              i_dt_begin       => i_begin_date,
                                                                                              i_dt_end         => i_end_date,
                                                                                              i_admission_date => i_admission_date)) gh) ho
                                ON pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                   i_date1 => pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                               t.dt_event),
                                                                   i_date2 => pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                               ho.dt_ho)) = 'E') at
                     WHERE at.dt_ho IS NULL) tt;
        
        END IF;
    
        IF i_cal_flg_type = g_holiday_signature
        THEN
            SELECT t_rec_note_type_dt(id_pn_note_type => i_id_pn_note_type,
                                      id_episode      => i_id_episode,
                                      dt_event        => pk_date_utils.convert_dt_tsz(i_lang => i_lang,
                                                                                      i_prof => i_prof,
                                                                                      i_date => h.dt_holiday))
              BULK COLLECT
              INTO l_tbl_type
              FROM holiday h
             WHERE h.dt_holiday >= CAST(i_begin_date AS DATE)
               AND h.dt_holiday <= CAST(l_end_date AS DATE)
               AND h.institution_key = i_prof.institution
               AND h.dt_holiday > CAST(i_admission_date AS DATE)
               AND h.record_status = pk_alert_constant.g_active;
        END IF;
    
        o_note_expect_note := l_tbl_type;
        l_return           := NOT (l_tbl_type IS NULL);
    
        RETURN l_return;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END calculate_dt;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_note_type_list         Note type list need to use
    * @param i_admission_date         Admission date
    * @param i_discharge_date         Discharge date
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    * @param o_expect_note            cursor with all expect note
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_expect_note
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_note_type_list IN t_coll_note_type_condition,
        i_admission_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_discharge_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_begin_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_expect_note    OUT t_coll_note_type_dt,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(50 CHAR) := 'GET_EXPECT_NOTE';
        l_tbl_note_type_dt      t_coll_note_type_dt := t_coll_note_type_dt();
        l_tbl_temp_note_type_dt t_coll_note_type_dt;
        l_count                 NUMBER;
    BEGIN
        g_error := 'i_note_type_list.count:' || i_note_type_list.count;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        --Get this profissional all episode expect note
        <<lup_thru_001>>
        FOR i IN 1 .. i_note_type_list.count
        LOOP
            g_error := 'id_pn_note_type:' || i_note_type_list(i).id_pn_note_type || ', note_tpye_desc:' || i_note_type_list(i)
                      .note_type_desc || ', cal_delay_time:' || i_note_type_list(i).cal_delay_time ||
                       ', cal_expect_date:' || i_note_type_list(i).cal_expect_date || ', flg_cal_type:' || i_note_type_list(i)
                      .flg_cal_type;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            IF calculate_dt(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_episode       => i_id_episode,
                            i_id_pn_note_type  => i_note_type_list(i).id_pn_note_type,
                            i_id_pn_area       => i_note_type_list(i).id_pn_area,
                            i_admission_date   => i_admission_date,
                            i_discharge_date   => i_discharge_date,
                            i_begin_date       => i_begin_date,
                            i_end_date         => i_end_date,
                            i_cal_flg_type     => i_note_type_list(i).flg_cal_type,
                            i_rule_day         => i_note_type_list(i).cal_expect_date,
                            o_note_expect_note => l_tbl_temp_note_type_dt,
                            o_error            => o_error)
            THEN
                <<lup_thru_002>>
                FOR j IN 1 .. l_tbl_temp_note_type_dt.count
                LOOP
                    IF i_note_type_list(i).flg_cal_type <> g_weekly_summary
                    THEN
                        SELECT COUNT(1)
                          INTO l_count
                          FROM (SELECT *
                                  FROM epis_pn ep
                                 WHERE ep.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c) epn
                         WHERE epn.id_pn_note_type = l_tbl_temp_note_type_dt(j).id_pn_note_type
                           AND epn.id_episode = l_tbl_temp_note_type_dt(j).id_episode
                           AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
                           AND ((pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => epn.dt_proposed) =
                               pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                  i_timestamp => l_tbl_temp_note_type_dt(j).dt_event) AND i_note_type_list(i)
                               .flg_cal_type <> g_progress_note) OR
                               pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => epn.dt_pn_date) =
                               pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                 i_timestamp => l_tbl_temp_note_type_dt(j).dt_event));
                    END IF;
                    IF i_note_type_list(i).flg_cal_type = g_weekly_summary
                    THEN
                        SELECT COUNT(1)
                          INTO l_count
                          FROM (SELECT *
                                  FROM epis_pn ep
                                 WHERE ep.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c) epn
                         WHERE epn.id_pn_note_type = l_tbl_temp_note_type_dt(j).id_pn_note_type
                           AND epn.id_episode = l_tbl_temp_note_type_dt(j).id_episode
                           AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
                           AND (check_weekly_summary_range(i_dt_event_date => l_tbl_temp_note_type_dt(j).dt_event,
                                                           i_dt            => epn.dt_pn_date) = 1 OR
                               check_weekly_summary_range(i_dt_event_date => l_tbl_temp_note_type_dt(j).dt_event,
                                                           i_dt            => epn.dt_proposed) = 1);
                    END IF;
                
                    IF l_count = 0
                    THEN
                        g_error := 'l_count = 0 dt_event: ' || l_tbl_temp_note_type_dt(j).dt_event ||
                                   'id_pn_note_type:' || l_tbl_temp_note_type_dt(j).id_pn_note_type;
                        pk_alertlog.log_info(g_error);
                        l_tbl_note_type_dt.extend;
                        l_tbl_note_type_dt(l_tbl_note_type_dt.last) := t_rec_note_type_dt(id_pn_note_type => l_tbl_temp_note_type_dt(j)
                                                                                                             .id_pn_note_type,
                                                                                          id_episode      => l_tbl_temp_note_type_dt(j)
                                                                                                             .id_episode,
                                                                                          dt_event        => l_tbl_temp_note_type_dt(j)
                                                                                                             .dt_event);
                    END IF;
                END LOOP lup_thru_002;
            END IF;
        END LOOP lup_thru_001;
    
        o_expect_note := l_tbl_note_type_dt;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_expect_note;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_note_type_list         Note type list need to use
    * @param i_pn_area_inter_name     all pn_area internal name
    * @param i_admission_date         Admission date
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    * @param o_expect_note            cursor with all expect note
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_exist_note
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE DEFAULT NULL,
        i_note_type_list     IN t_coll_note_type_condition,
        i_pn_area_inter_name IN VARCHAR2,
        i_admission_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_begin_date         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date           IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_exist_note_det     OUT t_coll_calendar_note_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(14 CHAR) := 'GET_EXIST_NOTE';
        l_tbl_calendar_note_det t_coll_calendar_note_det := t_coll_calendar_note_det();
        l_exist_note            pk_types.cursor_type;
        l_notes_texts           pk_types.cursor_type;
        l_addendums             pk_types.cursor_type;
        l_comments              pk_types.cursor_type;
        l_tbl_note_det          note_det_tbl;
        l_result                BOOLEAN;
    BEGIN
        g_error := 'i_id_episode:' || i_id_episode || 'l_begin_date:' || to_char(i_begin_date) || ', l_end_date:' ||
                   to_char(i_end_date) || ' i_pn_area_inter_name:' || i_pn_area_inter_name;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF NOT pk_prog_notes_grids.get_epis_prog_notes(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_id_episode     => i_id_episode,
                                                       i_id_patient     => NULL,
                                                       i_flg_scope      => NULL,
                                                       i_area           => i_pn_area_inter_name,
                                                       i_flg_desc_order => NULL,
                                                       i_start_record   => NULL,
                                                       i_num_records    => NULL,
                                                       i_search         => NULL,
                                                       i_filter         => NULL,
                                                       o_data           => l_exist_note,
                                                       o_notes_texts    => l_notes_texts,
                                                       o_addendums      => l_addendums,
                                                       o_comments       => l_comments,
                                                       o_error          => o_error)
        THEN
            --RAISE g_exception;
            g_error := 'g_exception:';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        END IF;
        FETCH l_exist_note BULK COLLECT
            INTO l_tbl_note_det;
        CLOSE l_exist_note;
    
        g_error := 'l_tbl_note_det.count:' || l_tbl_note_det.count;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        FOR i IN 1 .. l_tbl_note_det.count
        LOOP
            g_error := 'l_tbl_note_det:' || l_tbl_note_det(i).note_id;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            g_error := 'l_tbl_note_det(i).note_short_date' || l_tbl_note_det(i).note_short_date ||
                       ' l_tbl_note_det(i).note_short_hour:' || l_tbl_note_det(i).note_short_hour;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            l_tbl_calendar_note_det.extend;
            l_tbl_calendar_note_det(l_tbl_calendar_note_det.last) := t_rec_calendar_note_det(i_id_episode,
                                                                                             l_tbl_note_det(i).note_id,
                                                                                             pk_date_utils.get_timestamp_insttimezone(i_lang   => i_lang,
                                                                                                                                      i_prof   => i_prof,
                                                                                                                                      i_date   => l_tbl_note_det(i)
                                                                                                                                                  .note_short_date ||
                                                                                                                                                   pk_prog_notes_constants.g_space || l_tbl_note_det(i)
                                                                                                                                                  .note_short_hour ||
                                                                                                                                                   ':00',
                                                                                                                                      i_format => pk_date_utils.g_date_minute_format),
                                                                                             l_tbl_note_det(i)
                                                                                             .id_note_type,
                                                                                             to_clob(l_tbl_note_det(i)
                                                                                                     .note_type_desc),
                                                                                             l_tbl_note_det(i)
                                                                                             .note_flg_status,
                                                                                             l_tbl_note_det(i)
                                                                                             .note_flg_status_desc,
                                                                                             l_tbl_note_det(i)
                                                                                             .note_info_desc,
                                                                                             l_tbl_note_det(i)
                                                                                             .note_prof_signature,
                                                                                             l_tbl_note_det(i).id_prof,
                                                                                             l_tbl_note_det(i)
                                                                                             .note_flg_ok,
                                                                                             l_tbl_note_det(i)
                                                                                             .note_flg_cancel,
                                                                                             l_tbl_note_det(i)
                                                                                             .note_nr_addendums,
                                                                                             l_tbl_note_det(i)
                                                                                             .flg_editable,
                                                                                             l_tbl_note_det(i).flg_write,
                                                                                             l_tbl_note_det(i)
                                                                                             .viewer_category,
                                                                                             l_tbl_note_det(i)
                                                                                             .viewer_category_desc,
                                                                                             NULL);
        END LOOP;
    
        SELECT t_rec_calendar_note_det(cnd.id_episode,
                                       cnd.id_epis_pn,
                                       cnd.note_date_time,
                                       cnd.id_pn_note_type,
                                       cnd.note_type_desc,
                                       cnd.note_flg_status,
                                       cnd.note_flg_status_desc,
                                       cnd.note_info_desc,
                                       cnd.note_prof_signature,
                                       NULL, --cnd.id_prof,
                                       cnd.note_flg_ok,
                                       cnd.note_flg_cancel,
                                       cnd.note_nr_addendums,
                                       cnd.flg_editable,
                                       cnd.flg_write,
                                       cnd.viewer_category,
                                       cnd.viewer_category_desc,
                                       decode(cnd.note_flg_status,
                                              pk_prog_notes_constants.g_epis_pn_flg_submited,
                                              g_on_time,
                                              pk_prog_notes_constants.g_epis_pn_flg_status_c,
                                              NULL,
                                              get_exist_note_time_status(i_lang                => i_lang,
                                                                         i_prof                => i_prof,
                                                                         i_id_episode          => i_id_episode,
                                                                         i_flg_cal_time_filter => nc.flg_cal_time_filter,
                                                                         i_cal_delay_time      => nc.cal_delay_time,
                                                                         i_cal_icu_delay_time  => nc.cal_icu_delay_time,
                                                                         i_dt_create           => epn.dt_create,
                                                                         i_dt_pn_date          => epn.dt_pn_date,
                                                                         i_dt_admission        => i_admission_date)))
          BULK COLLECT
          INTO o_exist_note_det
          FROM (SELECT /*+ OPT_ESTIMATE(TABLE lbcnd ROWS=1) */
                 *
                  FROM TABLE(l_tbl_calendar_note_det) lbcnd) cnd
          JOIN (SELECT /*+ OPT_ESTIMATE(TABLE intl ROWS=1) */
                 *
                  FROM TABLE(i_note_type_list) intl) nc
            ON cnd.id_pn_note_type = nc.id_pn_note_type
          LEFT JOIN epis_pn epn
            ON cnd.id_epis_pn = epn.id_epis_pn
         WHERE cnd.note_date_time >= i_begin_date
           AND cnd.note_date_time <= i_end_date
         ORDER BY cnd.note_date_time;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_exist_note;

    /**************************************************************************
    * Use id_epis_pn to get diffrent description for this epis_pn, 
    * 1. If note is procedure note, the epis_pn description is id_task_type=g_task_ph_templ
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_nt_flg_type            PN_NOTE_TYPE flg_cal_type
    * @param i_epis_pn                epis_pn ID
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION note_det_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE DEFAULT NULL,
        i_nt_flg_type IN VARCHAR2,
        i_epis_pn     IN epis_pn.id_epis_pn%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(50 CHAR) := 'NOTE_DET_DESC';
        l_desc CLOB;
    BEGIN
        g_error := 'i_nt_flg_type:' || i_nt_flg_type || ', i_epis_pn:' || i_epis_pn;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF i_nt_flg_type = g_procedure_note
        THEN
            SELECT epdt.pn_note
              INTO l_desc
              FROM epis_pn_det epd
              JOIN epis_pn_det_task epdt
                ON epd.id_epis_pn_det = epdt.id_epis_pn_det
             WHERE epd.id_epis_pn = i_epis_pn
               AND (epdt.id_task_type = pk_prog_notes_constants.g_task_procedures OR
                   epdt.id_task_type = pk_prog_notes_constants.g_task_other_exams_req);
        END IF;
    
        RETURN l_desc;
    END note_det_desc;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_note_type_list         all note type list
    * @param i_exist_notes            all exist notes list
    * @param i_expect_notes           all expect notes list
    *
    * @param o_calendar_note_det      return calendar note detail to check status
    * @param o_note_det               cursor with all note detail
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-1                       
    **************************************************************************/
    FUNCTION get_note_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_note_type_list    IN t_coll_note_type_condition,
        i_exist_note_det    IN t_coll_calendar_note_det,
        i_expect_notes      IN t_coll_note_type_dt,
        o_calendar_note_det OUT t_coll_calendar_note_det,
        o_note_det          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(50 CHAR) := 'GET_NOTE_DET';
    BEGIN
        SELECT t_rec_calendar_note_det(id_episode           => t.id_episode,
                                       id_epis_pn           => t.id_epis_pn,
                                       note_date_time       => t.note_date_time,
                                       id_pn_note_type      => t.id_pn_note_type,
                                       note_type_desc       => to_clob(t.note_type_desc),
                                       note_flg_status      => t.note_flg_status,
                                       note_flg_status_desc => t.note_flg_status_desc,
                                       note_prof_signature  => t.note_prof_signature,
                                       note_info_desc       => t.note_info_desc,
                                       id_prof              => t.id_prof,
                                       note_flg_ok          => t.note_flg_ok,
                                       note_flg_cancel      => t.note_flg_cancel,
                                       note_nr_addendums    => t.note_nr_addendums,
                                       flg_editable         => t.flg_editable,
                                       flg_write            => t.flg_write,
                                       viewer_category      => t.viewer_category,
                                       viewer_category_desc => t.viewer_category_desc,
                                       time_status          => t.time_status)
          BULK COLLECT
          INTO o_calendar_note_det
          FROM (SELECT exi_t.id_episode,
                       exi_t.id_epis_pn,
                       exi_t.note_date_time,
                       exi_t.id_pn_note_type,
                       nvl(note_det_desc(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_id_episode  => exi_t.id_episode,
                                         i_nt_flg_type => nt.flg_cal_type,
                                         i_epis_pn     => exi_t.id_epis_pn),
                           exi_t.note_type_desc) note_type_desc,
                       exi_t.note_flg_status,
                       nvl(exi_t.note_flg_status_desc, pk_prog_notes_constants.g_space) note_flg_status_desc,
                       exi_t.note_info_desc,
                       exi_t.note_prof_signature,
                       exi_t.id_prof,
                       exi_t.note_flg_ok,
                       exi_t.note_flg_cancel,
                       exi_t.note_nr_addendums,
                       exi_t.flg_editable,
                       exi_t.flg_write,
                       exi_t.viewer_category,
                       exi_t.viewer_category_desc,
                       exi_t.time_status
                  FROM (SELECT /*+ OPT_ESTIMATE(TABLE iend ROWS=1) */
                         *
                          FROM TABLE(i_exist_note_det) iend) exi_t
                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE intl ROWS=1) */
                        *
                         FROM TABLE(i_note_type_list) intl) nt
                    ON exi_t.id_pn_note_type = nt.id_pn_note_type
                UNION ALL
                SELECT expect_t.id_episode,
                       0 id_epis_pn,
                       expect_t.dt_event,
                       expect_t.id_pn_note_type,
                       nt.note_type_desc note_type_desc,
                       pk_prog_notes_cal_condition.g_proposed note_flg_status,
                       pk_prog_notes_constants.g_open_parenthesis ||
                       pk_sysdomain.get_domain(pk_prog_notes_constants.g_sd_note_flg_status,
                                               pk_prog_notes_cal_condition.g_proposed,
                                               i_lang) || pk_prog_notes_constants.g_close_parenthesis note_flg_status_desc,
                       NULL note_info_desc,
                       NULL note_prof_signature, --note_prof_signature
                       NULL id_prof, --exi_t.id_prof
                       pk_alert_constant.g_no note_flg_ok, --exi_t.note_flg_ok
                       pk_alert_constant.g_no note_flg_cancel, --exi_t.note_flg_cancel
                       NULL note_nr_addendums, --note_nr_addendums
                       pk_alert_constant.g_yes flg_editable, --flg_editable
                       pk_alert_constant.g_yes flg_write, --exi_t.flg_write
                       NULL viewer_category, --exi_t.viewer_category,
                       NULL viewer_category_desc, --viewer_category_desc,
                       get_expect_note_time_status(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_episode         => expect_t.id_episode,
                                                   i_dt_event_date      => expect_t.dt_event,
                                                   i_flg_cal_type       => nt.flg_cal_type,
                                                   i_cal_delay_time     => nt.cal_delay_time,
                                                   i_cal_icu_delay_time => nt.cal_icu_delay_time) time_status
                  FROM (SELECT /*+ OPT_ESTIMATE(TABLE intl ROWS=1) */
                         *
                          FROM TABLE(i_expect_notes) ien) expect_t
                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE intl ROWS=1) */
                        *
                         FROM TABLE(i_note_type_list) intl) nt
                    ON expect_t.id_pn_note_type = nt.id_pn_note_type) t;
    
        OPEN o_note_det FOR
            SELECT t.id_episode,
                   t.id_epis_pn,
                   pk_prog_notes_constants.g_open_parenthesis ||
                   pk_date_utils.dt_chr_tsz(i_lang, t.note_date_time, i_prof.institution, i_prof.software) ||
                   pk_prog_notes_constants.g_space ||
                   pk_date_utils.date_char_hour_tsz(i_lang, t.note_date_time, i_prof.institution, i_prof.software) ||
                   pk_prog_notes_constants.g_close_parenthesis note_date_time_desc,
                   pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_timestamp => t.note_date_time,
                                                   i_timezone  => NULL) note_date_time,
                   t.id_pn_note_type,
                   to_char(t.note_type_desc) note_type_desc,
                   t.note_flg_status,
                   t.note_flg_status_desc,
                   t.note_info_desc, --CEMR-614
                   t.note_prof_signature,
                   t.id_prof,
                   t.note_flg_cancel,
                   t.note_nr_addendums,
                   t.flg_editable,
                   t.flg_write,
                   --t.viewer_category,
                   --t.viewer_category_desc,
                   t.time_status,
                   pk_date_utils.dt_chr_tsz(i_lang, t.note_date_time, i_prof.institution, i_prof.software) || '|' ||
                   t.id_pn_note_type uniq_det
              FROM (SELECT /*+ OPT_ESTIMATE(TABLE ocnd ROWS=1) */
                     *
                      FROM TABLE(o_calendar_note_det) ocnd) t;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_note_det;

    /**************************************************************************
    * Get all note every day status 
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_calendar_note_det      All calendar note detail data
    * @param i_note_type_condition    All Note type parameter
    * @param i_dates_of_week          All dates of week
    *
    * @param o_note_lists             cursor with the information for all notes
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-5                       
    **************************************************************************/
    FUNCTION get_note_status_icon_para
    (
        i_lang            IN language.id_language%TYPE,
        i_flg_status      IN VARCHAR2,
        i_flg_time_status IN VARCHAR2,
        o_icon            OUT VARCHAR2,
        o_color           OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_sys_domain_code VARCHAR2(20 CHAR) := 'EPIS_PN.FLG_STATUS';
    BEGIN
        o_icon  := NULL;
        o_color := pk_alert_constant.g_color_icon_medium_grey;
    
        IF i_flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                            pk_prog_notes_constants.g_epis_pn_flg_for_review,
                            pk_prog_notes_constants.g_epis_pn_flg_submited,
                            pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
        THEN
            o_icon := pk_sysdomain.get_img(i_lang => i_lang, i_code_dom => l_sys_domain_code, i_val => i_flg_status);
        END IF;
    
        IF (i_flg_status = pk_prog_notes_cal_condition.g_on_time OR
           i_flg_time_status = pk_prog_notes_cal_condition.g_on_time)
           AND i_flg_status NOT IN (pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_c,
                                    pk_prog_notes_constants.g_epis_pn_flg_submited,
                                    pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
        THEN
            o_color := pk_alert_constant.g_color_green;
        END IF;
        IF (i_flg_status = pk_prog_notes_cal_condition.g_delay OR
           i_flg_time_status = pk_prog_notes_cal_condition.g_delay)
           AND i_flg_status NOT IN (pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_c,
                                    pk_prog_notes_constants.g_epis_pn_flg_submited,
                                    pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
        THEN
            o_color := pk_alert_constant.g_color_red;
        END IF;
        RETURN TRUE;
    END get_note_status_icon_para;

    /**************************************************************************
    * Get all note every day status 
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_calendar_note_det      All calendar note detail data
    * @param i_note_type_condition    All Note type parameter
    * @param i_dates_of_week          All dates of week
    *
    * @param o_note_lists             cursor with the information for all notes
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-5                       
    **************************************************************************/
    FUNCTION get_note_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_calendar_note_det   IN t_coll_calendar_note_det,
        i_note_type_condition IN t_coll_note_type_condition,
        i_dates_of_week       IN table_timestamp,
        o_note_lists          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(50 CHAR) := 'GET_NOTE_STATUS';
        l_note_lists          t_coll_calendar_view := t_coll_calendar_view();
        l_note_list_rec       t_rec_calendar_view;
        l_status_one_day      table_varchar;
        l_time_status_one_day table_varchar;
        l_last_status         VARCHAR2(2 CHAR);
        l_last_status_icon    VARCHAR2(100 CHAR);
        l_last_status_color   VARCHAR2(50 CHAR);
        l_last_time_status    VARCHAR2(2 CHAR);
        l_last_num            NUMBER(6);
        l_temp_dt             table_varchar;
    
        l_flg_editable table_varchar;
    BEGIN
    
        FOR i IN 1 .. i_note_type_condition.count
        LOOP
            l_note_list_rec := t_rec_calendar_view(NULL,
                                                   table_varchar(),
                                                   table_varchar(),
                                                   table_varchar(),
                                                   table_varchar(),
                                                   table_varchar(),
                                                   table_varchar(),
                                                   table_varchar());
            FOR j IN 1 .. i_dates_of_week.count
            LOOP
                g_error := 'i_note_type_condition: ' || i_note_type_condition(i).id_pn_note_type || ', l_day_in_week:' ||
                           to_char(i_dates_of_week(j)) || ', j:' || j;
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            
                l_status_one_day      := table_varchar();
                l_time_status_one_day := table_varchar();
                l_flg_editable        := table_varchar();
            
                SELECT cnt.note_flg_status, cnt.time_status, cnt.flg_editable
                  BULK COLLECT
                  INTO l_status_one_day, l_time_status_one_day, l_flg_editable
                  FROM (SELECT /*+ OPT_ESTIMATE(TABLE icnd ROWS=1) */
                         *
                          FROM TABLE(i_calendar_note_det) icnd) cnt
                 WHERE cnt.id_pn_note_type = i_note_type_condition(i).id_pn_note_type
                   AND pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => cnt.note_date_time) =
                       pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => i_dates_of_week(j));
            
                l_note_list_rec.id_pn_note_type := i_note_type_condition(i).id_pn_note_type;
                l_last_num                      := 0;
                l_last_status                   := NULL;
                l_last_time_status              := NULL;
            
                FOR l IN 1 .. l_status_one_day.count
                LOOP
                    g_error := 'Calculate total record every date every note, if cancel, do not show
                    number, expect procedure note';
                    IF (l_status_one_day(l) <> pk_prog_notes_constants.g_epis_pn_flg_status_c)
                       OR (l_status_one_day(l) = pk_prog_notes_constants.g_epis_pn_flg_status_c AND i_note_type_condition(i)
                       .flg_cal_type = g_procedure_note)
                    THEN
                        l_last_num := l_last_num + 1;
                    END IF;
                
                    IF l_last_time_status IS NULL
                       OR l_last_time_status <> pk_prog_notes_cal_condition.g_delay
                    THEN
                        l_last_time_status := l_time_status_one_day(l);
                    END IF;
                
                    g_error := 'Check status piority';
                    g_error := 'proposed';
                    IF l_status_one_day(l) = pk_prog_notes_cal_condition.g_proposed
                    THEN
                        l_last_status := pk_prog_notes_cal_condition.g_proposed;
                    END IF;
                
                    IF l_last_status IS NULL
                       OR l_last_status <> pk_prog_notes_cal_condition.g_proposed
                    THEN
                        IF l_status_one_day(l) <> pk_prog_notes_constants.g_epis_pn_flg_status_c
                           OR (l_status_one_day(l) = pk_prog_notes_constants.g_epis_pn_flg_status_c AND i_note_type_condition(i)
                               .flg_cal_type = g_procedure_note)
                        THEN
                            l_last_status := l_status_one_day(l);
                        END IF;
                    END IF;
                
                    --Proceduer note future note non-editable and backgroup is gray
                    IF i_note_type_condition(i)
                     .flg_cal_type = g_procedure_note
                        AND l_flg_editable(l) = pk_alert_constant.g_no
                        AND i_note_type_condition(i).flg_edit_condition = pk_prog_notes_constants.g_flg_edit_util_now
                    THEN
                        l_last_time_status := g_future_proposed;
                    END IF;
                END LOOP;
            
                -- If note is proposed and number>1 then show number and backgroup is gray
                -- So we use last_time_status is FP(show number and backgroud is gray)
                IF l_last_status = g_proposed
                   AND l_last_num > 1
                THEN
                    l_last_time_status := g_future_proposed;
                END IF;
            
                --Finish specific date and note, calculate the last status
                IF (l_last_status <> pk_prog_notes_constants.g_epis_pn_flg_status_f AND l_last_num > 1)
                   OR (l_last_status = pk_prog_notes_cal_condition.g_proposed AND l_last_time_status IS NOT NULL)
                THEN
                    l_last_status := l_last_time_status;
                END IF;
                g_error := 'final id_pn_note_type:' || i_note_type_condition(i).id_pn_note_type || 'l_last_status:' ||
                           l_last_status || ', l_last_time_status:' || l_last_time_status || ' l_last_num:' ||
                           l_last_num;
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            
                IF NOT get_note_status_icon_para(i_lang            => i_lang,
                                                 i_flg_status      => l_last_status,
                                                 i_flg_time_status => l_last_time_status,
                                                 o_icon            => l_last_status_icon,
                                                 o_color           => l_last_status_color)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_temp_dt := table_varchar(pk_date_utils.dt_chr_tsz(i_lang, i_dates_of_week(j), i_prof),
                                           i_note_type_condition(i).flg_cal_type,
                                           l_last_status,
                                           l_last_status_icon,
                                           l_last_status_color,
                                           to_char(l_last_num),
                                           pk_date_utils.dt_chr_tsz(i_lang, i_dates_of_week(j), i_prof) || '|' || i_note_type_condition(i)
                                           .id_pn_note_type);
                CASE j
                    WHEN 1 THEN
                        l_note_list_rec.dt_1 := l_temp_dt;
                    WHEN 2 THEN
                        l_note_list_rec.dt_2 := l_temp_dt;
                    WHEN 3 THEN
                        l_note_list_rec.dt_3 := l_temp_dt;
                    WHEN 4 THEN
                        l_note_list_rec.dt_4 := l_temp_dt;
                    WHEN 5 THEN
                        l_note_list_rec.dt_5 := l_temp_dt;
                    WHEN 6 THEN
                        l_note_list_rec.dt_6 := l_temp_dt;
                    WHEN 7 THEN
                        l_note_list_rec.dt_7 := l_temp_dt;
                END CASE;
            END LOOP;
            l_note_lists.extend;
            l_note_lists(l_note_lists.last) := l_note_list_rec;
        END LOOP;
    
        OPEN o_note_lists FOR
            SELECT /*+ OPT_ESTIMATE(TABLE icnd ROWS=1) */
             *
              FROM TABLE(l_note_lists) x;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_note_status;

    /**************************************************************************
    * Get note time status
    * 
    * @param i_prof              Profissional ID
    * @param i_dt_begin          begin date
    * @param i_dt_end            end date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2018-01-12                       
    **************************************************************************/
    FUNCTION get_note_time_status
    (
        i_cal_delay_time IN NUMBER,
        i_date           IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(50 CHAR) := 'GET_NOTE_TIME_STATUS';
        l_calc      INTERVAL DAY(4) TO SECOND;
        l_return    VARCHAR2(10 CHAR);
        e_name_too_samll EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_name_too_samll, -01873);
    BEGIN
        l_calc  := current_timestamp - i_date;
        g_error := 'l_calc:' || l_calc || ' i_date:' || to_char(i_date);
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        CASE
            WHEN l_calc >= numtodsinterval(i_cal_delay_time, 'MINUTE') THEN
                l_return := pk_prog_notes_cal_condition.g_delay;
            WHEN l_calc < numtodsinterval(0, 'MINUTE') THEN
                l_return := NULL;
            ELSE
                l_return := pk_prog_notes_cal_condition.g_on_time;
        END CASE;
    
        RETURN l_return;
    EXCEPTION
        WHEN e_name_too_samll THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_note_time_status;

    /**************************************************************************
    * Get note type time status
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_nt_flg_type            PN_NOTE_TYPE flg_cal_type
    * @param i_epis_pn                epis_pn ID
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-18                       
    **************************************************************************/
    FUNCTION get_exist_note_time_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_flg_cal_time_filter IN pn_note_type_mkt.flg_cal_time_filter%TYPE,
        i_cal_delay_time      IN pn_note_type_mkt.cal_delay_time%TYPE,
        i_cal_icu_delay_time  IN pn_note_type_mkt.cal_icu_delay_time%TYPE,
        i_dt_create           IN epis_pn.dt_create%TYPE,
        i_dt_pn_date          IN epis_pn.dt_pn_date%TYPE,
        i_dt_admission        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name      VARCHAR2(50 CHAR) := 'GET_NOTE_TIME_STATUS';
        l_time_status    VARCHAR2(3 CHAR) := NULL;
        l_compare_time   TIMESTAMP WITH LOCAL TIME ZONE;
        l_cal_delay_time NUMBER;
        o_error          t_error_out;
    
        l_return VARCHAR2(10 CHAR);
        e_name_too_samll EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_name_too_samll, -01873);
    BEGIN
        g_error := 'i_flg_cal_time_filter:' || i_flg_cal_time_filter || ', i_dt_create:' || i_dt_create ||
                   ', i_dt_pn_date:' || i_dt_pn_date || ', i_dt_admission:' || i_dt_admission;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        --Check ICU 
        IF pk_bmng.check_patient_firt_time_in_icu(i_lang, i_prof, i_id_episode) = pk_alert_constant.g_yes
        THEN
            IF i_cal_icu_delay_time > 0
            THEN
                l_cal_delay_time := i_cal_icu_delay_time;
            ELSE
                l_cal_delay_time := i_cal_delay_time;
            END IF;
        ELSE
            l_cal_delay_time := i_cal_delay_time;
        END IF;
    
        IF i_flg_cal_time_filter = g_admission_date
        THEN
            l_compare_time := i_dt_admission;
        ELSIF i_flg_cal_time_filter = g_eips_pn_event_date
        THEN
            l_compare_time := i_dt_pn_date;
        ELSIF i_flg_cal_time_filter = g_eips_pn_create_date
        THEN
            l_compare_time := i_dt_create;
        ELSE
            l_compare_time := i_dt_create;
        END IF;
        g_error := 'l_compare_time:' || l_compare_time;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        g_error := 'current_timestamp:' || current_timestamp;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_return := get_note_time_status(i_cal_delay_time => l_cal_delay_time, i_date => l_compare_time);
        RETURN l_return;
    END get_exist_note_time_status;

    /**************************************************************************
    * Get note type(surposed) time status
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_nt_flg_type            PN_NOTE_TYPE flg_cal_type
    * @param i_epis_pn                epis_pn ID
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-18                       
    **************************************************************************/
    FUNCTION get_expect_note_time_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_dt_event_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_cal_type       IN pn_note_type_mkt.flg_cal_type%TYPE,
        i_cal_delay_time     IN pn_note_type_mkt.cal_delay_time%TYPE,
        i_cal_icu_delay_time IN pn_note_type_mkt.cal_icu_delay_time%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name      VARCHAR2(50 CHAR) := 'GET_EXPECT_NOTE_TIME_STATUS';
        l_cal_delay_time NUMBER;
        o_error          t_error_out;
    
        l_return VARCHAR2(10 CHAR);
        e_name_too_samll EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_name_too_samll, -01873);
    BEGIN
        g_error := 'i_flg_cal_type:' || i_flg_cal_type || ', i_cal_delay_time:' || i_cal_delay_time ||
                   ' i_dt_event_date:' || to_char(i_dt_event_date);
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_cal_delay_time := i_cal_delay_time;
        IF i_flg_cal_type = g_admission_problem_listing
        THEN
            --Check ICU 
            IF pk_bmng.check_patient_firt_time_in_icu(i_lang, i_prof, i_id_episode) = pk_alert_constant.g_yes
            THEN
                IF i_cal_icu_delay_time > 0
                THEN
                    l_cal_delay_time := i_cal_icu_delay_time;
                ELSE
                    l_cal_delay_time := i_cal_delay_time;
                END IF;
            ELSE
                l_cal_delay_time := i_cal_delay_time;
            END IF;
        END IF;
    
        l_return := get_note_time_status(i_cal_delay_time => l_cal_delay_time, i_date => i_dt_event_date);
    
        RETURN l_return;
    END get_expect_note_time_status;

    /**************************************************************************
    * Get note type(surposed) time status
    * 
    * @param i_dt_event_date     date
    * @param i_dt                date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2018-01-04                       
    **************************************************************************/
    FUNCTION check_weekly_summary_range
    (
        i_dt_event_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt            IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(50 CHAR) := 'CHECK_WEEKLY_SUMMARY_RANGE';
        l_return    NUMBER := 0;
        l_dt_sup    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_inf    TIMESTAMP WITH LOCAL TIME ZONE;
        k_interval CONSTANT NUMBER := 2;
    BEGIN
        g_error := 'i_dt_event_date:' || i_dt_event_date || ', i_dt:' || i_dt;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_dt_inf := i_dt + numtodsinterval(-k_interval, 'DAY');
        l_dt_sup := i_dt + numtodsinterval(k_interval, 'DAY');
        IF i_dt_event_date BETWEEN l_dt_inf AND l_dt_sup
        THEN
            l_return := 1;
        END IF;
    
        RETURN l_return;
    END check_weekly_summary_range;

    /**************************************************************************
    * Get holiday list
    * 
    * @param i_prof              Profissional ID
    * @param i_dt_begin          begin date
    * @param i_dt_end            end date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2018-01-12                       
    **************************************************************************/
    FUNCTION get_holidays
    (
        i_prof           IN profissional,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_admission_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN table_timestamp IS
        l_func_name VARCHAR2(50 CHAR) := 'CHECK_WEEKLY_SUMMARY_RANGE';
        l_dt_sup    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_inf    TIMESTAMP WITH LOCAL TIME ZONE;
        k_interval CONSTANT NUMBER := 2;
        l_return table_timestamp;
    BEGIN
        g_error := 'i_dt_begin:' || i_dt_begin || ', i_dt_end:' || i_dt_end || 'i_admission_date:' || i_admission_date;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        SELECT CAST(h.dt_holiday AS TIMESTAMP WITH LOCAL TIME ZONE)
          BULK COLLECT
          INTO l_return
          FROM holiday h
         WHERE h.dt_holiday >= CAST(i_dt_begin AS DATE)
           AND h.dt_holiday <= CAST(i_dt_end AS DATE)
           AND h.institution_key = i_prof.institution
           AND h.dt_holiday > CAST(i_admission_date AS DATE);
    
        RETURN l_return;
    END get_holidays;

    /**************************************************************************
    * Get canlendar first date
    * 
    * @param i_prof              Profissional ID
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7.3
    * @since                          2018-01-17                       
    **************************************************************************/
    FUNCTION get_first_date_of_week(i_prof IN profissional) RETURN NUMBER IS
        l_func_name VARCHAR2(50 CHAR) := 'GET_FIRST_DATE_OF_WEEK';
        -- Private constant declarations
        l_sysconf_name_of_fdate CONSTANT VARCHAR2(30 CHAR) := 'CALENDAR_VIEW_F_DATE_OF_WEEK';
        l_cal_fd_monday         CONSTANT VARCHAR2(1 CHAR) := 'M';
        l_cal_fd_sunday         CONSTANT VARCHAR2(1 CHAR) := 'S';
        l_fd_format VARCHAR2(10 CHAR);
        l_return    NUMBER;
    BEGIN
        -- date_format to decide calculate first date of week is Monday or Sunday ex.M or S
        l_fd_format := pk_sysconfig.get_config(i_code_cf => l_sysconf_name_of_fdate, i_prof => i_prof);
        IF l_fd_format = l_cal_fd_monday
        THEN
            l_return := 0;
        ELSIF l_fd_format = l_cal_fd_sunday
        THEN
            l_return := 1;
        ELSE
            l_return := 0;
        END IF;
    
        RETURN l_return;
    END get_first_date_of_week;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_prog_notes_cal_condition;
/
