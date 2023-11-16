/*-- Last Change Revision: $Rev: 2027686 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_oris IS

    -- Private Package Constants 
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    -- Minimum time interval between slots (minutes). Slots with durations below this value will not be create.
    g_sch_min_slot_interval CONSTANT sys_config.id_sys_config%TYPE := 'SCH_MIN_SLOT_INTERVAL';

    -- Scale interval
    g_sch_surgery_scale_interval CONSTANT sys_config.id_sys_config%TYPE := 'SCH_SURGERY_SCALE_INTERVAL';
    g_default_scale_interval     CONSTANT NUMBER(2) := 30;

    /* Surgery Schedule Event */
    g_surg_sch_event CONSTANT NUMBER(2) := 14;

    g_flg_interval_day   CONSTANT VARCHAR2(1) := 'D';
    g_flg_interval_week  CONSTANT VARCHAR2(1) := 'W';
    g_flg_timetable_view CONSTANT VARCHAR2(1) := 'T';
    g_flg_list_view      CONSTANT VARCHAR2(1) := 'L';

    g_flg_empty CONSTANT VARCHAR2(1) := 'E';
    g_flg_half  CONSTANT VARCHAR2(1) := 'H';
    g_flg_full  CONSTANT VARCHAR2(1) := 'F';

    g_default_surgery_begin_hour CONSTANT VARCHAR2(30) := '09:00h';
    g_sch_surgery_begin_hour VARCHAR2(30) := 'SCH_SURGERY_BEGIN_HOUR';
    g_domain_sr_sch_status CONSTANT VARCHAR2(30) := 'SURGERY_SCHEDULING_STATUS';

    /* Message for weekday 1 */
    g_msg_seg CONSTANT VARCHAR2(8) := 'SCH_T314';
    /* Message for weekday 2 */
    g_msg_ter CONSTANT VARCHAR2(8) := 'SCH_T315';
    /* Message for weekday 3 */
    g_msg_qua CONSTANT VARCHAR2(8) := 'SCH_T316';
    /* Message for weekday 4 */
    g_msg_qui CONSTANT VARCHAR2(8) := 'SCH_T317';
    /* Message for weekday 5 */
    g_msg_sex CONSTANT VARCHAR2(8) := 'SCH_T318';
    /* Message for weekday 6 */
    g_msg_sab CONSTANT VARCHAR2(8) := 'SCH_T319';
    /* Message for weekday 7 */
    g_msg_dom CONSTANT VARCHAR2(8) := 'SCH_T320';
    /*Message for get_sr_dep_list function */
    g_msg_all_deps CONSTANT VARCHAR2(8) := 'SCH_T359';
    /*Message for get_sr_rooms function */
    g_msg_all_rooms CONSTANT VARCHAR2(8) := 'SCH_T358';

    /*messages for validate_schedule*/
    g_msg_no_proper_slot    CONSTANT VARCHAR2(8) := 'SCH_T394';
    g_msg_no_proper_vacancy CONSTANT VARCHAR2(8) := 'SCH_T395';
    g_msg_no_dcs_present    CONSTANT VARCHAR2(8) := 'SCH_T396';
    g_msg_dif_urgency_level CONSTANT VARCHAR2(8) := 'SCH_T397';
    g_msg_no_prof_present   CONSTANT VARCHAR2(8) := 'SCH_T398';
    g_msg_prof_unav         CONSTANT VARCHAR2(8) := 'SCH_T399';
    g_msg_pref_dt_begin     CONSTANT VARCHAR2(8) := 'SCH_T400';
    g_msg_pref_dt_end       CONSTANT VARCHAR2(8) := 'SCH_T401';
    g_msg_dpb               CONSTANT VARCHAR2(8) := 'SCH_T402';
    g_msg_dpa               CONSTANT VARCHAR2(8) := 'SCH_T403';
    g_msg_sched_overlap     CONSTANT VARCHAR2(8) := 'SCH_T404';
    g_msg_no_avail          CONSTANT VARCHAR2(8) := 'SCH_T418';
    g_msg_pat_unav          CONSTANT VARCHAR2(8) := 'SCH_T466';
    g_msg_rec_surg_date     CONSTANT VARCHAR2(8) := 'SCH_T486';

    /* All identifier */
    g_all                   CONSTANT NUMBER(2) := -10;
    g_msg_all_surgeons      CONSTANT VARCHAR2(30) := 'SCH_T387';
    g_msg_surgical_procs    CONSTANT VARCHAR2(30) := 'SCH_T388';
    g_msg_all_status        CONSTANT VARCHAR2(30) := 'SCH_T405';
    g_msg_temporary         CONSTANT VARCHAR2(30) := 'SCH_T416';
    g_msg_final             CONSTANT VARCHAR2(30) := 'SCH_T417';
    g_msg_all_scpecialities CONSTANT VARCHAR2(30) := 'SCH_T419';
    g_temporary VARCHAR2(1) := 'Y';
    g_final     VARCHAR(1) := 'N';
    g_msg_cancelled CONSTANT VARCHAR2(30) := 'SCH_T420';
    g_canceled VARCHAR(1) := 'C';
    g_msg_scheduled      CONSTANT VARCHAR2(30) := 'SCH_T481';
    g_msg_unscheduled    CONSTANT VARCHAR2(30) := 'SCH_T482';
    g_msg_temporarysch   CONSTANT VARCHAR2(30) := 'SCH_T483';
    g_msg_hour_indicator CONSTANT VARCHAR2(30) := 'HOURS_SIGN';

    /* week period formats */
    g_week_format_simple CONSTANT VARCHAR2(30) := 'SCH_T800';
    g_week_format_double CONSTANT VARCHAR2(30) := 'SCH_T801';
    g_week_format_triple CONSTANT VARCHAR2(30) := 'SCH_T802';

    /*validate schedule stop error*/
    g_stop_error CONSTANT INTEGER := 500;

    -- Private Package Variables

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(30);
    /* Stores the package owner. */
    g_package_owner VARCHAR2(30);
    /* Cursor Aux. Flag */
    g_found BOOLEAN;
    /* sysdate */
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;

    /* surgery department type */
    g_surgery_dep_type CONSTANT VARCHAR2(1) := 'S';

    /* Indicates if the professional is the Admiting phisician */
    g_sr_prof_type CONSTANT VARCHAR(1) := 'A';
    /* Indicates if it is the surgery specialty */
    g_sr_specialty CONSTANT VARCHAR(1) := 'S';

    -- Functions and Procedures

    /**********************************************************************************************
    * Gets Waiting List ID of a Schedule
    *
    * @param i_id_schedule                   Schedule ID
    *
    * @return                                Waiting List ID
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/21
    **********************************************************************************************/
    FUNCTION get_id_wl(i_id_schedule IN schedule_sr.id_schedule%TYPE) RETURN NUMBER IS
        l_id_wl     schedule_sr.id_waiting_list%TYPE;
        l_func_name VARCHAR2(32) := 'GET_ID_DEP_FROM_ROOM';
    BEGIN
    
        g_error := 'SELECT schedule_sr';
        SELECT id_waiting_list
          INTO l_id_wl
          FROM schedule_sr
         WHERE id_schedule = i_id_schedule;
    
        RETURN l_id_wl;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_id_wl;

    /**********************************************************************************************
    * Gets the abreviation of a month
    *
    * @param i_lang                          Language ID
    * @param i_month_index                   Month index
    *
    * @return                                Abreviation of month
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/29
    **********************************************************************************************/
    FUNCTION get_month_abrev
    (
        i_lang        IN language.id_language%TYPE,
        i_month_index IN NUMBER
    ) RETURN VARCHAR2 IS
        l_month VARCHAR2(30);
    BEGIN
    
        g_error := 'SELECT schedule_sr';
        SELECT desc_message
          INTO l_month
          FROM sys_message
         WHERE id_language = i_lang
           AND code_message LIKE 'TL_MON_' || i_month_index;
    
        RETURN l_month;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_month_abrev;

    /*
    * insert or update in table room_scheduled.
    * Adapted from pk_sr_visit.upd_surg_proc_preview_room. Didn't use that one because it's got a commit inside.
    * @author Telmo
    */
    FUNCTION upd_room_scheduled
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_room     IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_id_room room.id_room%TYPE;
        --        l_schedule    schedule.id_schedule%TYPE;
        l_id_episode   schedule_sr.id_episode%TYPE;
        l_idroomsched  room_scheduled.id_room_scheduled%TYPE;
        l_dt_begin     schedule.dt_begin_tstz%TYPE;
        l_dt_end       schedule.dt_end_tstz%TYPE;
        l_dt_scheduled schedule.dt_schedule_tstz%TYPE;
        l_rowsid       table_varchar;
    BEGIN
        --Obtém a sala agendada actualmente
        g_error := 'GET CURRENT ROOM';
        BEGIN
            SELECT id_room
              INTO l_cur_id_room
              FROM room_scheduled
             WHERE id_schedule = i_id_schedule
               AND flg_status = g_active;
        EXCEPTION
            WHEN no_data_found THEN
                l_cur_id_room := NULL;
        END;
    
        --Só actualiza a sala se ainda não existir ou for diferente da actual
        IF nvl(l_cur_id_room, -1) != i_id_room
        THEN
            --Só pode haver uma sala activa para cada agendamento, por isso, cancela as anteriores
            g_error := 'UPDATE OLD ROOM STATUS';
            UPDATE room_scheduled
               SET flg_status = pk_sr_visit.g_cancel
             WHERE id_schedule = i_id_schedule
               AND flg_status = g_active;
        
            --Obtém ID do agendamento
            BEGIN
                g_error := 'GET ID_SCHEDULE';
                SELECT id_episode, dt_begin_tstz, s.dt_end_tstz, s.dt_schedule_tstz
                  INTO l_id_episode, l_dt_begin, l_dt_end, l_dt_scheduled
                  FROM schedule s
                 WHERE id_schedule = i_id_schedule;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            IF i_id_schedule IS NOT NULL
            THEN
                --Actualiza sala prevista do agendamento
                g_error := 'INSERT INTO ROOM_SCHEDULED';
                INSERT INTO room_scheduled
                    (id_room_scheduled,
                     dt_room_scheduled_tstz,
                     id_schedule,
                     id_room,
                     flg_status,
                     dt_start_tstz,
                     dt_end_tstz)
                VALUES
                    (seq_room_scheduled.nextval,
                     l_dt_scheduled,
                     i_id_schedule,
                     i_id_room,
                     pk_sr_visit.g_flg_status_active,
                     l_dt_begin,
                     l_dt_end)
                RETURNING id_room_scheduled INTO l_idroomsched;
            
                IF l_id_episode IS NOT NULL
                THEN
                    g_error := 'UPDATE EPIS_INFO';
                    ts_epis_info.upd(id_episode_in          => l_id_episode,
                                     id_room_scheduled_in   => l_idroomsched,
                                     room_sch_flg_status_in => pk_sr_visit.g_flg_status_active,
                                     rows_out               => l_rowsid);
                END IF;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPD_SURG_PROC_PREVIEW_ROOM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_room_scheduled;

    /**********************************************************************************************
    * This function converts days on hour:min format
    *
    * @param i_lang                          Language ID
    * @param i_days                          number of days
    *
    * @return                                formated HH24:MI
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION days_to_hourmin
    (
        i_lang IN language.id_language%TYPE,
        i_days IN NUMBER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN to_char(trunc(i_days * 24), 'FM900') || ':' || to_char(MOD(i_days * 24 * 60, 60), 'FM00') || pk_message.get_message(i_lang,
                                                                                                                                   g_msg_hour_indicator); --'h';
    END days_to_hourmin;

    /**********************************************************************************************
    * This function determine the grid header text
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_flg_interval                  Flag date interval: D-Daily; W-Weekly
    * @param i_flg_viewtype                  View: T-Timetable view; L-List view
    * @param o_header_text                   Grid header text with HTML Tags for bold text
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_grid_header
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_date         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_interval IN VARCHAR2,
        i_flg_viewtype IN VARCHAR2,
        o_header_text  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'GET_GRID_HEADER';
        l_year           NUMBER(4);
        l_month          NUMBER(2);
        l_day            NUMBER(2);
        l_week           NUMBER(2);
        l_msg_or         sys_message.desc_message%TYPE;
        l_str_out        sys_message.desc_message%TYPE;
        l_desc_view      sys_message.desc_message%TYPE;
        l_period_label   sys_message.desc_message%TYPE;
        l_first_day_week TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_last_day_week  TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_first_year     NUMBER(4);
        l_first_month    NUMBER(2);
        l_first_day      NUMBER(2);
        l_last_year      NUMBER(4);
        l_last_month     NUMBER(2);
        l_last_day       NUMBER(2);
        l_mask           sys_message.desc_message%TYPE;
        l_date           VARCHAR2(4001);
    
    BEGIN
        g_error := 'GET MESSAGE SCH_T355';
        -- Operating Room label
        l_msg_or := pk_message.get_message(i_lang, 'SCH_T355');
    
        g_error := 'GET MESSAGE SCH_T356/SCH_T357';
        -- View type label: Timetable / List View
        IF i_flg_viewtype = g_flg_timetable_view
        THEN
            -- Table View
            l_desc_view := pk_message.get_message(i_lang, 'SCH_T357');
        ELSIF i_flg_viewtype = g_flg_list_view
        THEN
            --List View
            l_desc_view := pk_message.get_message(i_lang, 'SCH_T356');
        END IF;
    
        IF i_flg_interval = g_flg_interval_day
        THEN
            -- Daily View
            g_error        := 'DAILY VIEW';
            l_mask         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SCH_T765');
            l_period_label := initcap(pk_message.get_message(i_lang, 'SCH_T304'));
        
            g_error := 'CALL pk_schedule.get_dmy_string_date';
            IF NOT pk_schedule.get_dmy_string_date(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_date           => pk_date_utils.date_send_tsz(i_lang, i_date, i_prof),
                                                   o_described_date => l_date,
                                                   o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_str_out := l_period_label || ': <B>' || l_date;
        ELSIF i_flg_interval = g_flg_interval_week
        THEN
            -- Weekly View
            g_error          := 'WEEKLY VIEW HEADER ASSEMBLY';
            l_period_label   := initcap(pk_message.get_message(i_lang, 'SCH_T305'));
            l_first_day_week := pk_date_utils.trunc_insttimezone(i_prof, i_date, 'DAY');
            l_last_day_week  := pk_date_utils.add_days_to_tstz(l_first_day_week, 6);
            l_week           := pk_date_utils.date_week_tsz(i_lang,
                                                            l_first_day_week,
                                                            i_prof.institution,
                                                            i_prof.software);
            l_first_year     := pk_date_utils.date_year_tsz(i_lang,
                                                            l_first_day_week,
                                                            i_prof.institution,
                                                            i_prof.software);
            l_last_year      := pk_date_utils.date_year_tsz(i_lang,
                                                            l_last_day_week,
                                                            i_prof.institution,
                                                            i_prof.software);
            l_first_month    := pk_date_utils.date_month_tsz(i_lang,
                                                             l_first_day_week,
                                                             i_prof.institution,
                                                             i_prof.software);
            l_last_month     := pk_date_utils.date_month_tsz(i_lang,
                                                             l_last_day_week,
                                                             i_prof.institution,
                                                             i_prof.software);
            l_first_day      := pk_date_utils.date_day_tsz(i_lang,
                                                           l_first_day_week,
                                                           i_prof.institution,
                                                           i_prof.software);
            l_last_day       := pk_date_utils.date_day_tsz(i_lang, l_last_day_week, i_prof.institution, i_prof.software);
        
            l_str_out := l_period_label || ': <B>';
        
            IF l_first_year = l_last_year
            THEN
                IF l_first_month = l_last_month
                THEN
                    l_str_out := l_str_out ||
                                 pk_message.get_message(i_lang => i_lang, i_code_mess => g_week_format_simple);
                ELSE
                    l_str_out := l_str_out ||
                                 pk_message.get_message(i_lang => i_lang, i_code_mess => g_week_format_double);
                END IF;
            ELSE
                l_str_out := l_str_out || pk_message.get_message(i_lang => i_lang, i_code_mess => g_week_format_triple);
            END IF;
        
            -- replace values
            l_str_out := REPLACE(l_str_out, '@weeknum', l_week);
            l_str_out := REPLACE(l_str_out, '@firstday', l_first_day);
            l_str_out := REPLACE(l_str_out, '@lastday', l_last_day);
            l_str_out := REPLACE(l_str_out,
                                 '@firstmonth',
                                 pk_message.get_message(i_lang, 'SCH_MONTH_' || l_first_month));
            l_str_out := REPLACE(l_str_out, '@lastmonth', pk_message.get_message(i_lang, 'SCH_MONTH_' || l_last_month));
            l_str_out := REPLACE(l_str_out, '@firstyear', l_first_year);
            l_str_out := REPLACE(l_str_out, '@lastyear', l_last_year);
        END IF;
    
        g_error   := 'CONCATENATE COMMON TEXT';
        l_str_out := l_str_out || ' - ' || l_msg_or || '</B> (' || l_desc_view || ')';
    
        o_header_text := l_str_out;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_header_text := NULL;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_grid_header;

    /**********************************************************************************************
    * Get Scale cursor for Daily or Weekly view
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_flg_interval                  Flag date interval: D-Daily; W-Weekly
    * @param o_begin_hour                    First display hour - time scale (Daily view)
    * @param o_cursor                        Scale values
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_scale
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_interval   IN VARCHAR2,
        o_begin_hour     OUT VARCHAR2,
        o_cursor         OUT pk_types.cursor_type,
        o_cursor_weekend OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'GET_SCALE';
        l_scale_interval sys_config.value%TYPE;
        l_tab_scale      table_varchar := table_varchar();
        l_tab_weekend    table_varchar := table_varchar();
        l_dt_aux         TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_weekday        NUMBER;
        l_desc_weekday   sys_message.desc_message%TYPE;
        l_intervals      NUMBER;
    BEGIN
    
        IF i_flg_interval = g_flg_interval_day
        THEN
            -- Daily view
            g_error      := 'GET CONFIG VALUE FOR SCH_SURGERY_BEGIN_HOUR';
            o_begin_hour := nvl(pk_sysconfig.get_config(i_code_cf => g_sch_surgery_begin_hour, i_prof => i_prof),
                                g_default_surgery_begin_hour);
        
            g_error          := 'GET SYSCONFIG - SCALE INTERVAL';
            l_scale_interval := nvl(pk_sysconfig.get_config(i_code_cf => g_sch_surgery_scale_interval, i_prof => i_prof),
                                    g_default_scale_interval);
            IF l_scale_interval <= 0
            THEN
                l_scale_interval := g_default_scale_interval;
            END IF;
        
            l_intervals := 24 * 60 / l_scale_interval;
        
            l_dt_aux := pk_date_utils.trunc_insttimezone(i_prof, i_date); --trunc(i_date);
            --o_week   := to_char(l_dt_aux, 'WW');
        
            l_tab_scale.extend(l_intervals);
            FOR i IN 1 .. l_intervals
            LOOP
                l_tab_scale(i) := pk_date_utils.date_hourmin_tsz(i_lang, l_dt_aux, i_prof.institution, i_prof.software); --to_char(l_dt_aux, 'HH24:MI');
                l_dt_aux := pk_date_utils.add_to_ltstz(l_dt_aux, l_scale_interval, 'MINUTE');
            END LOOP;
        
        ELSIF i_flg_interval = g_flg_interval_week
        THEN
            -- Weekly view
            g_error := 'BUILD TABLE WITH WEEKDAYS';
            l_tab_scale.extend(7);
            l_tab_weekend.extend(7);
            l_dt_aux := pk_date_utils.trunc_insttimezone(i_prof, i_date, 'DAY'); --trunc(i_date, 'DAY');
            --o_week   := to_char(l_dt_aux, 'WW');
        
            FOR idx IN 1 .. 7
            LOOP
                g_error := 'GET STANDARD WEEKDAY';
                l_weekday := week_day_standard(l_dt_aux); --week_day_standard(l_dt_aux);
                g_error := 'GET WEEKDAY DESCRIPTION';
                l_desc_weekday := pk_message.get_message(i_lang,
                                                         CASE l_weekday
                                                             WHEN 1 THEN
                                                              g_msg_seg
                                                             WHEN 2 THEN
                                                              g_msg_ter
                                                             WHEN 3 THEN
                                                              g_msg_qua
                                                             WHEN 4 THEN
                                                              g_msg_qui
                                                             WHEN 5 THEN
                                                              g_msg_sex
                                                             WHEN 6 THEN
                                                              g_msg_sab
                                                             WHEN 7 THEN
                                                              g_msg_dom
                                                         END);
                l_tab_scale(idx) := l_desc_weekday || ' ' ||
                                   --pk_date_utils.date_day_tsz(i_lang, l_dt_aux, i_prof.institution, i_prof.software);
                                    to_char(l_dt_aux, 'DD');
                l_tab_weekend(idx) := CASE
                                          WHEN l_weekday IN (6, 7) THEN
                                           'Y'
                                          ELSE
                                           'N'
                                      END;
                l_dt_aux := pk_date_utils.add_days_to_tstz(l_dt_aux, 1);
            END LOOP;
        END IF;
    
        g_error := 'OPEN O_CURSOR';
        OPEN o_cursor FOR
            SELECT a.column_value scale
              FROM TABLE(l_tab_scale) a;
    
        OPEN o_cursor_weekend FOR
            SELECT b.column_value flg_weekend
              FROM TABLE(l_tab_weekend) b;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_cursor);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_scale;

    /**
    * returns header with rooms names and their department name. For use in the daily and weekly grids
    *
    * @param i_lang     language id
    * @param i_room_ids list of room ids to retrieve info
    * @param o_rooms    results
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Telmo
    * @version 2.5
    * @date    03-04-2009
    */
    FUNCTION get_rooms_header
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_room_ids       IN table_number,
        o_rooms          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ROOMS_HEADER';
    BEGIN
        g_error := 'OPEN cursor';
        OPEN o_rooms FOR
            SELECT r.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) desc_dep
              FROM room r
              JOIN department d
                ON r.id_department = d.id_department
             WHERE (i_room_ids IS NULL OR cardinality(i_room_ids) = 0 OR
                   r.id_room IN (SELECT *
                                    FROM TABLE(i_room_ids)))
               AND r.flg_available = g_yes
               AND d.id_institution = i_id_institution
               AND d.flg_available = g_yes
               AND d.flg_type = g_surgery_dep_type
             ORDER BY desc_dep, d.id_department, desc_room, r.id_room;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_rooms);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rooms_header;

    /**********************************************************************************************
    * Determine the SUM (in hours) of a vacancy slot
    *
    * @param i_lang                          Language ID
    *
    * @return                                formatted text with sum hours
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_total_slothours
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_TOTAL_SLOTHOURS';
        l_tot_days  NUMBER;
    BEGIN
        g_error := 'SELECT SUM SLOT DAYS';
        SELECT nvl(SUM(pk_date_utils.get_timestamp_diff(schcvos.dt_end, schcvos.dt_begin)), 0)
          INTO l_tot_days
          FROM sch_consult_vac_oris_slot schcvos
         WHERE schcvos.id_sch_consult_vacancy = i_id_sch_consult_vacancy;
    
        RETURN days_to_hourmin(i_lang, l_tot_days);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_total_slothours;

    /**********************************************************************************************
    * Round a date, according the interval parameter
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array   
    *
    * @return                                formatted text with sum hours
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION round_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name                  VARCHAR2(30) := 'ROUND_DATE';
        l_sch_surgery_scale_interval sys_config.value%TYPE;
        l_hour                       NUMBER(2);
        l_min                        NUMBER(2);
        l_round                      NUMBER(2);
        l_years                      NUMBER(12);
        l_months                     NUMBER(2);
        l_days                       NUMBER(2);
        l_seconds                    NUMBER(24);
        l_date                       TIMESTAMP WITH TIME ZONE;
        l_timezone                   timezone_region.timezone_region%TYPE;
        l_error                      t_error_out;
    BEGIN
        g_error := 'CALL PK_DATE_UTILS.GET_TIMEZONE';
        IF (pk_date_utils.get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => l_error))
        THEN
            g_error := 'TIMESTAMP AT TIMEZONE';
            l_date  := i_date at TIME ZONE l_timezone;
        
            g_error                      := 'SELECT SCALE INTERVAL PARAMETER FROM SYS_CONFIG';
            l_sch_surgery_scale_interval := pk_sysconfig.get_config(g_sch_surgery_scale_interval, i_prof);
        
            g_error := 'CALL PK_DATE_UTILS.EXTRACT_FROM_TSTZ';
            IF NOT (pk_date_utils.extract_from_tstz(i_lang,
                                                    i_prof,
                                                    l_date,
                                                    l_years,
                                                    l_months,
                                                    l_days,
                                                    l_hour,
                                                    l_min,
                                                    l_seconds,
                                                    l_error))
            THEN
                RETURN NULL;
            END IF;
            --l_hour  := extract(hour FROM l_date);
            --l_min   := extract(minute FROM l_date);
            l_round := l_min - MOD(l_min, to_number(l_sch_surgery_scale_interval));
        
            RETURN to_char(l_hour, 'FM00') || ':' || to_char(l_round, 'FM00');
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END round_date;

    /********************************************************************************************
    * This function returns a value from 1 to 7 identifying the day of the week, where
    * Monday is 1 and Sunday is 7.
    * Note: In Oracle, depending on the NLS_Territory setting, different days of the week are 1.
    * Examples:
    *   U.S., Canada, Monday = 2;  Most European countries, Monday = 1;
    *   Most Middle-Eastern countries, Monday = 3.
    *   For Bangladesh, Monday = 4.
    *
    * @param i_date          Input date parameter
    *
    * @return                Return the day of the week
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/03/03
    ********************************************************************************************/
    FUNCTION week_day_standard(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN NUMBER IS
    BEGIN
        RETURN 1 + MOD(to_number(to_char(i_date, 'J')), 7);
    END week_day_standard;

    /**********************************************************************************************
    * This function returns then DepClinServ Description
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_dep_clin_serv              DepClinServ ID
    * @param i_id_sch_consult_vacancy        Vacancy ID
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_dep_clin_serv_name
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_dep_clin_serv       dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name             VARCHAR2(30) := 'GET_DEP_CLIN_SERV_NAME';
        l_code_clinical_service clinical_service.code_clinical_service%TYPE;
    BEGIN
        g_error := 'SELECT CODE CLINICAL SERVICE';
    
        SELECT code_clinical_service
          INTO l_code_clinical_service
          FROM clinical_service
         WHERE id_clinical_service = (SELECT id_clinical_service
                                        FROM dep_clin_serv
                                       WHERE id_dep_clin_serv =
                                             nvl(i_id_dep_clin_serv,
                                                 (SELECT id_dep_clin_serv
                                                    FROM sch_consult_vacancy
                                                   WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy))
                                         AND flg_available = g_yes
                                         AND rownum = 1)
           AND flg_available = 'Y';
    
        RETURN pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code_clinical_service);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_dep_clin_serv_name;

    /**********************************************************************************************
    * This function returns vacancy IDs collection
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_room_ids                      Table with room IDs
    * @param i_begin_date                    Input begin date   
    * @param i_end_date                      Input end date   
    * @param o_vacancy_ids                   Vancacy IDs collection
    * @param o_error                         Error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_vacancies
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_room_ids    IN table_number,
        i_begin_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_vacancy_ids OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE rec_vacancies IS RECORD(
            permission VARCHAR2(10),
            id_vancacy NUMBER(24));
        TYPE tab_vacancies IS TABLE OF rec_vacancies;
    
        l_func_name   VARCHAR2(30) := 'GET_VACANCIES';
        l_idx         NUMBER;
        l_vacancy_ids tab_vacancies;
    BEGIN
    
        g_error := 'GET VACANCIES';
        SELECT pk_schedule.has_permission(i_lang, i_prof, scv.id_dep_clin_serv, scv.id_sch_event, scv.id_prof),
               scv.id_sch_consult_vacancy
          BULK COLLECT
          INTO l_vacancy_ids
          FROM sch_consult_vacancy scv
         INNER JOIN sch_consult_vac_oris scvo
            ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
         WHERE scv.id_institution = i_prof.institution
           AND scv.id_sch_event IN (SELECT id_sch_event
                                      FROM sch_event
                                     WHERE dep_type = g_surgery_dep_type)
           AND (scv.id_room IN (SELECT column_value
                                  FROM TABLE(i_room_ids)) OR i_room_ids IS NULL OR cardinality(i_room_ids) = 0)
           AND dt_begin_tstz >= i_begin_date
           AND dt_begin_tstz < i_end_date
           AND scv.flg_status = pk_schedule_bo.g_status_active;
    
        -- ATENTION: performance reason-> do not filter on sql query
        IF cardinality(l_vacancy_ids) > 0
        THEN
            l_idx         := 1;
            o_vacancy_ids := table_number();
        
            FOR idx IN l_vacancy_ids.first .. l_vacancy_ids.last
            LOOP
                IF l_vacancy_ids(idx).permission = 'TRUE'
                THEN
                    o_vacancy_ids.extend;
                    o_vacancy_ids(l_idx) := l_vacancy_ids(idx).id_vancacy;
                    l_idx := l_idx + 1;
                END IF;
            END LOOP;
        END IF;
    
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
        
    END get_vacancies;

    /**********************************************************************************************
    * Make UNION operation set between i_dept_ids and i_room_ids
    *
    * @param i_lang                          Language ID
    * @param i_dept_ids                      Department IDs
    * @param i_room_ids                      Room IDs
    *
    * @return                                table number - UNION result
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_union_rooms
    (
        i_lang     IN language.id_language%TYPE,
        i_dept_ids IN table_number,
        i_room_ids IN table_number
    ) RETURN table_number IS
        l_func_name VARCHAR2(30) := 'GET_UNION_ROOMS';
        l_room_ids  table_number;
    BEGIN
        g_error := 'GET ROOMS BY DEPARTMENT IDs LIST';
        IF NOT i_dept_ids IS NULL
           OR cardinality(i_dept_ids) > 0
        THEN
            SELECT id_room
              BULK COLLECT
              INTO l_room_ids
              FROM room r
             WHERE r.id_department IN (SELECT column_value
                                         FROM TABLE(i_dept_ids))
               AND r.flg_available = g_yes;
        END IF;
    
        l_room_ids := l_room_ids MULTISET UNION DISTINCT i_room_ids;
    
        RETURN l_room_ids;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_union_rooms;

    /**********************************************************************************************
    * This function returns the grid header text, grid top rooms descriptions, unit time scale,
    * current week number, for a date, room list and interval (D-Day / W-Week)
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_dept_ids                      Table with department IDs
    * @param i_room_ids                      Table with room IDs
    * @param i_flg_interval                  Flag date interval: D-Day; W-Week
    * @param o_rooms                         Rooms descriptions
    * @param o_begin_hour                    Scale begin hour to display on grid
    * @param o_scale_cursor                  Scale cursor
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_timetable_layout
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_date         IN VARCHAR2,
        i_dept_ids     IN table_number,
        i_room_ids     IN table_number,
        i_flg_interval IN VARCHAR2,
        o_rooms        OUT pk_types.cursor_type,
        o_begin_hour   OUT VARCHAR2,
        o_scale_cursor OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cursor_dummy pk_types.cursor_type;
        l_func_name    VARCHAR2(30) := 'GET_TIMETABLE_LAYOUT';
        l_date         TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_room_ids     table_number;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CONVERT INPUT DATE FROM STRING TO TSTZ FORMAT';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PRIVATE FUNCTION: GET_SCALE';
        IF i_flg_interval = g_flg_interval_day
        THEN
            IF NOT get_scale(i_lang           => i_lang,
                             i_prof           => i_prof,
                             i_date           => l_date,
                             i_flg_interval   => i_flg_interval,
                             o_begin_hour     => o_begin_hour,
                             o_cursor         => o_scale_cursor,
                             o_cursor_weekend => l_cursor_dummy,
                             o_error          => o_error)
            THEN
                pk_date_utils.set_dst_time_check_on;
                RETURN FALSE;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_scale_cursor);
        END IF;
    
        g_error    := 'CALL GET_UNION_ROOMS FUNCTION';
        l_room_ids := get_union_rooms(i_lang => i_lang, i_dept_ids => i_dept_ids, i_room_ids => i_room_ids);
    
        g_error := 'CALL PRIVATE FUNCTION: GET_ROOMS_HEADER';
        IF NOT get_rooms_header(i_lang           => i_lang,
                                i_id_institution => i_prof.institution,
                                i_room_ids       => l_room_ids,
                                o_rooms          => o_rooms,
                                o_error          => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_begin_hour := NULL;
            pk_types.open_my_cursor(o_scale_cursor);
            pk_types.open_my_cursor(o_rooms);
            pk_date_utils.set_dst_time_check_on;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_timetable_layout;

    /**********************************************************************************************
    * Function to return the color for use in sessions / schedules
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param i_id_dcs                    Dep_clin_serv ID
    * @param i_flg_urgency               Flag urgency
    * @param i_flg_sch                   Flag Schedule (Y or N)
    * @param i_date                      Date
    *
    * @return                            table number - UNION result
    *
    * @author                            Nuno Miguel Ferreira
    * @version                           2.5
    * @since                             2009/03/31
    **********************************************************************************************/
    FUNCTION get_color
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_dcs      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_urgency VARCHAR2,
        i_flg_sch     VARCHAR2,
        i_date        TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name   VARCHAR2(30) := 'GET_COLOR';
        l_color_name  sch_color.color_name%TYPE;
        l_color       sch_color.color_hex%TYPE;
        l_past        BOOLEAN;
        l_flg_urgency BOOLEAN;
        l_aux_flg     NUMBER(1);
        l_use_colors  sys_config.value%TYPE;
        o_error       t_error_out;
    BEGIN
        g_error       := 'DECISION RULE';
        l_past        := pk_date_utils.get_timestamp_diff(i_date, current_timestamp) <= 0;
        l_flg_urgency := (i_flg_urgency = g_yes);
        l_aux_flg     := 0;
    
        g_error := 'GET DCS COLOR USAGE';
        -- Check if DCS colors are used
        IF NOT pk_schedule.get_config(i_lang         => i_lang,
                                      i_id_sysconfig => pk_schedule.g_config_use_dcs_colors,
                                      i_prof         => i_prof,
                                      o_config       => l_use_colors,
                                      o_error        => o_error)
        THEN
            RETURN NULL;
        END IF;
    
        IF l_use_colors = g_yes
        THEN
            IF l_flg_urgency
               AND l_past
            THEN
                l_color_name := 'PAST_URGENCY_SESSION_COLOR';
            ELSIF l_flg_urgency
                  AND NOT l_past
            THEN
                l_color_name := 'URGENCY_SESSION_COLOR';
            ELSIF NOT l_flg_urgency
                  AND l_past
            THEN
                l_color_name := 'FULL_BACKGROUND_COLOR';
            ELSE
                IF i_flg_sch = g_yes
                THEN
                    l_color_name := 'FULL_BACKGROUND_COLOR';
                ELSE
                    l_aux_flg := 1;
                END IF;
            END IF;
        
            IF l_aux_flg = 1
            THEN
                SELECT color_hex
                  INTO l_color
                  FROM sch_color
                 WHERE id_institution IN (0, i_prof.institution)
                   AND flg_type = g_color_flg_type_d
                   AND sch_color.id_dep_clin_serv = i_id_dcs;
            
            ELSE
                SELECT color_hex
                  INTO l_color
                  FROM sch_color
                 WHERE id_institution IN (0, i_prof.institution)
                   AND flg_type = g_color_flg_type_n
                   AND sch_color.color_name = l_color_name;
            END IF;
        END IF;
    
        IF l_color IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN '0x' || l_color;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_color;

    /**********************************************************************************************
    * This function returns the grid body information in Timetable View format for a day
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_dept_ids                      Table with department IDs
    * @param i_room_ids                      Table with room IDs
    * @param o_header_text                   Grid header text with HTML Tags for bold text    
    * @param o_daily_info                    Output cursor with daily information
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_timetable_daily_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_date        IN VARCHAR2,
        i_dept_ids    IN table_number,
        i_room_ids    IN table_number,
        o_header_text OUT VARCHAR2,
        o_daily_info  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                  VARCHAR2(30) := 'GET_TIMETABLE_DAILY_INFO';
        l_sch_surgery_scale_interval sys_config.value%TYPE;
        l_date                       TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_room_ids                   table_number;
        l_vacancy_ids                table_number := table_number();
        l_msg_sch_t386               sys_message.desc_message%TYPE;
    
        l_internal_error EXCEPTION;
    BEGIN
        g_error                      := 'SELECT SCALE INTERVAL PARAMETER FROM SYS_CONFIG';
        l_sch_surgery_scale_interval := pk_sysconfig.get_config(g_sch_surgery_scale_interval, i_prof);
    
        g_error        := 'GET SCH_T386 MESSAGE';
        l_msg_sch_t386 := pk_message.get_message(i_lang, 'SCH_T386');
    
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CONVERT INPUT DATE FROM STRING TO TSTZ FORMAT';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL PRIVATE FUNCTION: GET_GRID_HEADER';
        IF NOT get_grid_header(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_date         => l_date,
                               i_flg_interval => g_flg_interval_day,
                               i_flg_viewtype => g_flg_timetable_view,
                               o_header_text  => o_header_text,
                               o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error    := 'CALL GET_UNION_ROOMS FUNCTION';
        l_room_ids := get_union_rooms(i_lang => i_lang, i_dept_ids => i_dept_ids, i_room_ids => i_room_ids);
    
        g_error := 'DETERMINE VACANCIES - CALL FUNCTION GET_VACANCIES';
        l_date  := pk_date_utils.trunc_insttimezone(i_prof, l_date);
        IF NOT get_vacancies(i_lang        => i_lang,
                             i_prof        => i_prof,
                             i_room_ids    => l_room_ids,
                             i_begin_date  => l_date,
                             i_end_date    => pk_date_utils.add_days_to_tstz(l_date, 1),
                             o_vacancy_ids => l_vacancy_ids,
                             o_error       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        IF cardinality(l_vacancy_ids) = 0
        THEN
            pk_types.open_my_cursor(o_daily_info);
            --RAISE l_internal_error;
        END IF;
    
        g_error := 'OPEN CURSOR FOR VACANCY IDS';
        OPEN o_daily_info FOR
        --Vacancies
            SELECT 1 reg_type_num,
                   'SESSION' reg_type_str,
                   schcv.id_sch_consult_vacancy id_record,
                   schcvo.flg_urgency,
                   schcv.id_room,
                   pk_schedule_oris.round_date(i_lang, i_prof, schcv.dt_begin_tstz) round_date,
                   ceil(pk_date_utils.get_timestamp_diff(schcv.dt_end_tstz, schcv.dt_begin_tstz) * 24 * 60 /
                        to_number(l_sch_surgery_scale_interval)) paint_cells,
                   '<B>' || get_total_slothours(i_lang, schcv.id_sch_consult_vacancy) || '/' ||
                   days_to_hourmin(i_lang, pk_date_utils.get_timestamp_diff(schcv.dt_end_tstz, schcv.dt_begin_tstz)) || ' ' ||
                   l_msg_sch_t386 || ', ' ||
                   pk_date_utils.date_char_hour_tsz(i_lang, schcv.dt_begin_tstz, i_prof.institution, i_prof.software) || '-' || --to_char(schcv.dt_begin_tstz, 'HH24:MI') || 'h-' ||
                   pk_date_utils.date_char_hour_tsz(i_lang, schcv.dt_end_tstz, i_prof.institution, i_prof.software) ||
                   '; </B>' || get_dep_clin_serv_name(i_lang, i_prof, schcv.id_dep_clin_serv, NULL) dailyinfo,
                   get_color(i_lang, i_prof, schcv.id_dep_clin_serv, schcvo.flg_urgency, g_no, schcv.dt_end_tstz) colorcell
              FROM sch_consult_vacancy schcv
             INNER JOIN sch_consult_vac_oris schcvo
                ON schcv.id_sch_consult_vacancy = schcvo.id_sch_consult_vacancy
             WHERE schcv.id_sch_consult_vacancy IN (SELECT column_value
                                                      FROM TABLE(l_vacancy_ids))
            
            UNION ALL
            -- Schedules
            SELECT 2 reg_type_num,
                   'SCH' reg_type_str,
                   sch.id_schedule,
                   schcvo.flg_urgency,
                   sch.id_room,
                   pk_schedule_oris.round_date(i_lang, i_prof, sch.dt_begin_tstz) round_date,
                   ceil(pk_date_utils.get_timestamp_diff(sch.dt_end_tstz, sch.dt_begin_tstz) * 24 * 60 /
                        to_number(l_sch_surgery_scale_interval)) paint_cells,
                   '<B>' ||
                   days_to_hourmin(i_lang, pk_date_utils.get_timestamp_diff(sch.dt_end_tstz, sch.dt_begin_tstz)) || ', ' ||
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_begin_tstz, i_prof.institution, i_prof.software) || '-' ||
                   
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_end_tstz, i_prof.institution, i_prof.software) ||
                   '; </B>' ||
                   
                   get_dep_clin_serv_name(i_lang, i_prof, NULL, sch.id_schedule) || ', ' ||
                   pk_wtl_pbl_core.get_surg_proc_string(i_lang, i_prof, ss.id_waiting_list) || ', ' ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) || ', ' ||
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, sch.id_episode) || ', ' ||
                   pk_wtl_pbl_core.get_danger_cont_string(i_lang, i_prof, sch.id_episode, ss.id_waiting_list) dailyinfo,
                   get_color(i_lang, i_prof, sch.id_dcs_requested, g_no, g_yes, sch.dt_end_tstz)
              FROM schedule sch
             INNER JOIN sch_consult_vac_oris schcvo
                ON sch.id_sch_consult_vacancy = schcvo.id_sch_consult_vacancy
             INNER JOIN schedule_sr ss
                ON sch.id_schedule = ss.id_schedule
             INNER JOIN sch_resource sr
                ON sch.id_schedule = sr.id_schedule
             INNER JOIN sch_group sg
                ON sch.id_schedule = sg.id_schedule
             WHERE sch.id_sch_consult_vacancy IN (SELECT column_value
                                                    FROM TABLE(l_vacancy_ids))
               AND sch.flg_status != g_canceled;
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_header_text := NULL;
            pk_types.open_my_cursor(o_daily_info);
            pk_date_utils.set_dst_time_check_on;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_timetable_daily_info;

    /**********************************************************************************************
    * This function returns the grid body information in Timetable View format for a week (i_date' s week)
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_dept_ids                      Table with department IDs    
    * @param i_room_ids                      Table with room IDs
    * @param o_header_text                   Grid header text with HTML Tags for bold text    
    * @param o_weekly_info                   Output cursor with daily information
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_timetable_weekly_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN VARCHAR2,
        i_dept_ids       IN table_number,
        i_room_ids       IN table_number,
        o_header_text    OUT VARCHAR2,
        o_scale_cursor   OUT pk_types.cursor_type,
        o_cursor_weekend OUT pk_types.cursor_type,
        o_weekly_info    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'GET_TIMETABLE_WEEKLY_INFO';
        l_date           TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_room_ids       table_number;
        l_first_day_week TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_last_day_week  TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_vacancy_ids    table_number;
        l_msg_sch_t386   sys_message.desc_message%TYPE;
        l_dummy1         VARCHAR2(200);
    BEGIN
        g_error        := 'GET SCH_T386 MESSAGE';
        l_msg_sch_t386 := pk_message.get_message(i_lang, 'SCH_T386');
    
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CONVERT INPUT DATE FROM STRING TO TSTZ FORMAT';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PRIVATE FUNCTION: GET_GRID_HEADER';
        IF NOT get_grid_header(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_date         => l_date,
                               i_flg_interval => g_flg_interval_week,
                               i_flg_viewtype => g_flg_timetable_view,
                               o_header_text  => o_header_text,
                               o_error        => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PRIVATE FUNCTION: GET_SCALE';
        IF NOT get_scale(i_lang           => i_lang,
                         i_prof           => i_prof,
                         i_date           => l_date,
                         i_flg_interval   => g_flg_interval_week,
                         o_begin_hour     => l_dummy1,
                         o_cursor         => o_scale_cursor,
                         o_cursor_weekend => o_cursor_weekend,
                         o_error          => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error    := 'CALL GET_UNION_ROOMS FUNCTION';
        l_room_ids := get_union_rooms(i_lang => i_lang, i_dept_ids => i_dept_ids, i_room_ids => i_room_ids);
    
        g_error          := 'DETERMINE FIRST AND LAST WEEK DAYS';
        l_first_day_week := pk_date_utils.trunc_insttimezone(i_prof, l_date, 'DAY'); --trunc(l_date, 'DAY');
        l_last_day_week  := pk_date_utils.add_days_to_tstz(l_first_day_week, 7);
    
        g_error := 'DETERMINE VACANCIES - CALL FUNCTION GET_VACANCIES';
        l_date  := pk_date_utils.trunc_insttimezone(i_prof, l_date); --trunc(l_date);
        IF NOT get_vacancies(i_lang        => i_lang,
                             i_prof        => i_prof,
                             i_room_ids    => l_room_ids,
                             i_begin_date  => l_first_day_week,
                             i_end_date    => l_last_day_week,
                             o_vacancy_ids => l_vacancy_ids,
                             o_error       => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        IF cardinality(l_vacancy_ids) = 0
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_weekly_info);
            RETURN TRUE;
        END IF;
    
        g_error := 'OPEN O_WEEKLY_INFO CURSOR';
        OPEN o_weekly_info FOR
            SELECT pk_message.get_message(i_lang,
                                          CASE weekday
                                              WHEN 1 THEN
                                               g_msg_seg
                                              WHEN 2 THEN
                                               g_msg_ter
                                              WHEN 3 THEN
                                               g_msg_qua
                                              WHEN 4 THEN
                                               g_msg_qui
                                              WHEN 5 THEN
                                               g_msg_sex
                                              WHEN 6 THEN
                                               g_msg_sab
                                              WHEN 7 THEN
                                               g_msg_dom
                                          END) || ' ' || truncdate weekday,
                   --pk_date_utils.date_day_tsz(i_lang, truncdate, i_prof.institution, i_prof.software) weekday,
                   --to_char(truncdate, 'DD') weekday,
                   id_room,
                   weeklyinfo,
                   flg_urgency,
                   get_color(i_lang, i_prof, id_dep_clin_serv, decode(flg_urgency, 0, g_no, g_yes), g_yes, max_dt_end) colorcell
              FROM (SELECT pk_schedule_oris.week_day_standard(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                               dt_begin_tstz,
                                                                                               'SS')) weekday, --pk_schedule_oris.week_day_standard(dt_begin_tstz) weekday,
                           --trunc(schcv.dt_begin_tstz ) truncdate,
                           pk_date_utils.date_day_tsz(i_lang, schcv.dt_begin_tstz, i_prof.institution, i_prof.software) truncdate,
                           schcv.id_room,
                           schcv.id_dep_clin_serv,
                           '<B>' ||
                           pk_schedule_oris.days_to_hourmin(i_lang,
                                                            SUM(pk_date_utils.get_timestamp_diff(schcvos.dt_end,
                                                                                                 schcvos.dt_begin))) || '/' ||
                           pk_schedule_oris.days_to_hourmin(i_lang,
                                                            SUM(pk_date_utils.get_timestamp_diff(schcv.dt_end_tstz,
                                                                                                 schcv.dt_begin_tstz))) || ' ' ||
                           l_msg_sch_t386 || ', </B>' ||
                           get_dep_clin_serv_name(i_lang, i_prof, schcv.id_dep_clin_serv, NULL) weeklyinfo,
                           SUM(decode(schcvo.flg_urgency, g_yes, 1, 0)) flg_urgency,
                           MAX(schcv.dt_end_tstz) max_dt_end
                      FROM sch_consult_vacancy schcv
                     INNER JOIN sch_consult_vac_oris schcvo
                        ON schcv.id_sch_consult_vacancy = schcvo.id_sch_consult_vacancy
                     INNER JOIN sch_consult_vac_oris_slot schcvos
                        ON schcv.id_sch_consult_vacancy = schcvos.id_sch_consult_vacancy
                     WHERE schcv.id_sch_consult_vacancy IN (SELECT column_value
                                                              FROM TABLE(l_vacancy_ids))
                     GROUP BY pk_schedule_oris.week_day_standard(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                  schcv.dt_begin_tstz,
                                                                                                  'SS')), --pk_schedule_oris.week_day_standard(schcv.dt_begin_tstz),
                              pk_date_utils.date_day_tsz(i_lang,
                                                         schcv.dt_begin_tstz,
                                                         i_prof.institution,
                                                         i_prof.software),
                              --trunc(schcv.dt_begin_tstz),
                              id_room,
                              schcv.id_dep_clin_serv
                     ORDER BY 2, 1, 3);
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_weekly_info);
            pk_date_utils.set_dst_time_check_on;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_timetable_weekly_info;

    /**********************************************************************************************
    * Gets Department ID of a room
    *
    * @param i_id_room                       Room ID
    *
    * @return                                Department ID
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/17
    **********************************************************************************************/
    FUNCTION get_id_dep_from_room(i_id_room IN room.id_room%TYPE) RETURN NUMBER IS
        l_id_dep    department.id_department%TYPE := 0;
        l_func_name VARCHAR2(32) := 'GET_ID_DEP_FROM_ROOM';
    BEGIN
    
        g_error := 'SELECT';
        SELECT r.id_department
          INTO l_id_dep
          FROM room r
         WHERE r.id_room = i_id_room;
    
        RETURN l_id_dep;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
        
    END get_id_dep_from_room;

    /**********************************************************************************************
    * Gets Department Name of a room
    *
    * @param i_id_room                       Room ID
    *
    * @return                                Department ID
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/17
    **********************************************************************************************/
    FUNCTION get_dep_name_from_room
    (
        i_lang    IN language.id_language%TYPE,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR2 IS
        l_dep_name  VARCHAR2(4000);
        l_func_name VARCHAR2(32) := 'GET_DEP_NAME_FROM_ROOM';
    BEGIN
    
        g_error := 'SELECT';
        SELECT pk_translation.get_translation(i_lang, d.code_department)
          INTO l_dep_name
          FROM room r, department d
         WHERE r.id_department = d.id_department
           AND r.id_room = i_id_room;
    
        RETURN l_dep_name;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_dep_name_from_room;

    /**********************************************************************************************
    * Gets status of a session: (E)mpty, (H)alf and (F)ull
    *
    * @param i_id_sch_consult_vacancy        Session ID
    *
    * @return                                Status of session
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/20
    **********************************************************************************************/
    FUNCTION get_session_status(i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE) RETURN VARCHAR IS
        l_status           VARCHAR2(1);
        l_dt_begin_session sch_consult_vacancy.dt_begin_tstz%TYPE;
        l_dt_end_session   sch_consult_vacancy.dt_end_tstz%TYPE;
        l_dt_begin_slot    sch_consult_vac_oris_slot.dt_begin%TYPE;
        l_dt_end_slot      sch_consult_vac_oris_slot.dt_end%TYPE;
        l_func_name        VARCHAR2(32) := 'GET_SESSION_STATUS';
    BEGIN
    
        g_error := 'SELECT';
        SELECT scv.dt_begin_tstz, scv.dt_end_tstz, scvos.dt_begin, scvos.dt_end
          INTO l_dt_begin_session, l_dt_end_session, l_dt_begin_slot, l_dt_end_slot
          FROM sch_consult_vac_oris_slot scvos, sch_consult_vacancy scv
         WHERE scvos.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
           AND scv.id_sch_consult_vacancy = i_id_sch_consult_vacancy
           AND rownum = 1;
    
        IF l_dt_begin_session = l_dt_begin_slot
           AND l_dt_end_session = l_dt_end_slot
        THEN
            l_status := g_flg_empty;
        ELSE
            l_status := g_flg_half;
        END IF;
    
        RETURN l_status;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN g_flg_full;
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_session_status;

    /**********************************************************************************************
    * This function returns the grid body information in Timetable View format for a week (i_date' s week)
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_dept_ids                      Table with department IDs    
    * @param i_room_ids                      Table with room IDs
    * @param o_header_text                   String with header information
    * @param o_listview_info                 Output cursor with sessions, schedules and slots information
    * @param o_colors                        Output cursor with colors information
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION get_listview_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN VARCHAR2,
        i_dept_ids      IN table_number,
        i_room_ids      IN table_number,
        i_flg_interval  IN VARCHAR2,
        o_header_text   OUT VARCHAR2,
        o_listview_info OUT pk_types.cursor_type,
        o_colors        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30) := 'GET_LISTVIEW_INFO';
        l_date        TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_begin_date  TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_end_date    TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_room_ids    table_number;
        l_vacancy_ids table_number;
        l_mask        sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                              i_code_mess => 'SCH_T768');
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        g_error := 'CONVERT INPUT DATE FROM STRING TO TSTZ FORMAT';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PRIVATE FUNCTION: GET_GRID_HEADER';
        IF NOT get_grid_header(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_date         => l_date,
                               i_flg_interval => i_flg_interval,
                               i_flg_viewtype => g_flg_list_view,
                               o_header_text  => o_header_text,
                               o_error        => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        g_error    := 'CALL GET_UNION_ROOMS FUNCTION';
        l_room_ids := get_union_rooms(i_lang => i_lang, i_dept_ids => i_dept_ids, i_room_ids => i_room_ids);
    
        g_error := 'DETERMINE BEGIN AND END DATE';
        IF i_flg_interval = g_flg_interval_day
        THEN
            l_begin_date := pk_date_utils.trunc_insttimezone(i_prof, l_date);
            l_end_date   := pk_date_utils.add_days_to_tstz(l_begin_date, 1);
        ELSE
            l_begin_date := pk_date_utils.trunc_insttimezone(i_prof, l_date, 'DAY');
            l_end_date   := pk_date_utils.add_days_to_tstz(l_begin_date, 7);
        END IF;
    
        g_error := 'DETERMINE VACANCIES - CALL FUNCTION GET_VACANCIES';
        IF NOT get_vacancies(i_lang        => i_lang,
                             i_prof        => i_prof,
                             i_room_ids    => l_room_ids,
                             i_begin_date  => l_begin_date,
                             i_end_date    => l_end_date,
                             o_vacancy_ids => l_vacancy_ids,
                             o_error       => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        IF cardinality(l_vacancy_ids) = 0
        THEN
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_listview_info);
            pk_types.open_my_cursor(o_colors);
            RETURN TRUE;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_listview_info FOR
        -- Vacancies
            SELECT 1 regtype,
                   'SESSION' reg_type_str,
                   decode(pk_schedule_oris.get_session_status(schcv.id_sch_consult_vacancy),
                          g_flg_empty,
                          pk_schedule.g_icon_prefix || pk_sysdomain.get_img(i_lang, 'SCH_SURGERY', g_flg_empty),
                          pk_schedule.g_icon_prefix || pk_sysdomain.get_img(i_lang, 'SCH_SURGERY', g_flg_full)) icon_reg_type,
                   schcv.id_sch_consult_vacancy,
                   NULL id_sch_consult_vac_oris_slot,
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, schcv.dt_begin_tstz, l_mask) AS daymonth,
                   pk_date_utils.date_year_tsz(i_lang, schcv.dt_begin_tstz, i_prof.institution, i_prof.software) YEAR,
                   pk_date_utils.date_char_hour_tsz(i_lang, schcv.dt_begin_tstz, i_prof.institution, i_prof.software) begin_hour,
                   pk_date_utils.date_char_hour_tsz(i_lang, schcv.dt_end_tstz, i_prof.institution, i_prof.software) end_hour,
                   pk_date_utils.date_send_tsz(i_lang, schcv.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, schcv.dt_end_tstz, i_prof) dt_end,
                   pk_date_utils.date_yearmonthday_tsz(i_lang, schcv.dt_begin_tstz, i_prof.institution, i_prof.software) year_month_day,
                   pk_date_utils.date_send_tsz(i_lang, schcv.dt_begin_tstz, i_prof) begin_session,
                   id_room,
                   nvl((SELECT r.desc_room
                         FROM room r
                        WHERE r.id_room = schcv.id_room),
                       pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || schcv.id_room)) room_name,
                   get_id_dep_from_room(schcv.id_room) id_dep,
                   get_dep_name_from_room(i_lang, schcv.id_room) dep_name,
                   NULL id_patient,
                   NULL patient_name,
                   NULL pat_ndo,
                   NULL pat_nd_icon,
                   schcv.id_dep_clin_serv,
                   get_dep_clin_serv_name(i_lang, i_prof, schcv.id_dep_clin_serv, NULL) desc_dcs,
                   NULL id_schedule,
                   NULL surgery_name,
                   schcv.id_prof id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, schcv.id_prof) prof_name,
                   NULL id_episode,
                   NULL id_waiting_list,
                   pk_schedule_oris.get_session_status(schcv.id_sch_consult_vacancy) flg_color_session,
                   get_color(i_lang, i_prof, schcv.id_dep_clin_serv, g_no, g_no, current_timestamp + INTERVAL '1' DAY) color_dcs,
                   to_char(extract(hour FROM(schcv.dt_end_tstz - schcv.dt_begin_tstz)), 'FM00') || ':' ||
                   to_char(extract(minute FROM(schcv.dt_end_tstz - schcv.dt_begin_tstz)), 'FM00') ||
                   pk_message.get_message(i_lang, g_msg_hour_indicator) vac_total_hours,
                   get_total_slothours(i_lang, schcv.id_sch_consult_vacancy) vac_free_hours,
                   NULL flg_temporary,
                   NULL notif_status,
                   NULL notif_icon_status,
                   NULL sch_status,
                   NULL icon_sch_status,
                   NULL extend_icon,
                   '' flg_registered
              FROM sch_consult_vacancy schcv
             WHERE schcv.id_sch_consult_vacancy IN (SELECT column_value
                                                      FROM TABLE(l_vacancy_ids))
            -- Schedules
            UNION ALL
            
            SELECT 2 regtype,
                   'SCHEDULE' reg_type_str,
                   pk_schedule.g_icon_prefix || pk_sysdomain.get_img(i_lang, 'SCH_SURGERY', 'C') icon_reg_type,
                   sch.id_sch_consult_vacancy,
                   NULL id_sch_consult_vac_oris_slot,
                   pk_date_utils.date_daymonth_tsz(i_lang, sch.dt_begin_tstz, i_prof.institution, i_prof.software) daymonth,
                   pk_date_utils.date_year_tsz(i_lang, sch.dt_begin_tstz, i_prof.institution, i_prof.software) YEAR,
                   pk_date_utils.date_char_hour_tsz(i_lang, sch.dt_begin_tstz, i_prof.institution, i_prof.software) begin_hour,
                   pk_date_utils.date_char_hour_tsz(i_lang, sch.dt_end_tstz, i_prof.institution, i_prof.software) end_hour,
                   pk_date_utils.date_send_tsz(i_lang, sch.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, sch.dt_end_tstz, i_prof) dt_end,
                   pk_date_utils.date_yearmonthday_tsz(i_lang, sch.dt_begin_tstz, i_prof.institution, i_prof.software) year_month_day,
                   pk_date_utils.date_send_tsz(i_lang, schcv.dt_begin_tstz, i_prof) begin_session,
                   sch.id_room,
                   nvl((SELECT r.desc_room
                         FROM room r
                        WHERE r.id_room = sch.id_room),
                       pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || sch.id_room)) room_name,
                   get_id_dep_from_room(sch.id_room) id_dep,
                   get_dep_name_from_room(i_lang, sch.id_room) dep_name,
                   schg.id_patient,
                   --VIPs
                   pk_patient.get_pat_name(i_lang, i_prof, schg.id_patient, sch.id_episode) patient_name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, schg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, schg.id_patient) pat_nd_icon,
                   --
                   sch.id_dcs_requested id_dep_clin_serv,
                   get_dep_clin_serv_name(i_lang, i_prof, sch.id_dcs_requested, NULL) desc_dcs,
                   sch.id_schedule id_schedule,
                   pk_wtl_pbl_core.get_surg_proc_string(i_lang, i_prof, ss.id_waiting_list) surgery_name,
                   sr.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) prof_name,
                   sch.id_episode,
                   ss.id_waiting_list,
                   'S' flg_color_session,
                   NULL color_dcs,
                   NULL vac_total_hours,
                   NULL vac_free_hours,
                   ss.flg_temporary,
                   sch.flg_notification notif_status,
                   pk_schedule.g_icon_prefix ||
                   pk_sysdomain.get_img(i_lang, pk_schedule.g_sched_flg_notif_status, flg_notification) notif_icon_status,
                   sch.flg_status sch_status,
                   decode(ss.flg_temporary,
                          g_yes,
                          pk_schedule.g_icon_prefix || pk_schedule.g_sched_icon_temp,
                          pk_schedule.g_icon_prefix ||
                          pk_sysdomain.get_img(i_lang, pk_schedule.g_schedule_flg_status_domain, sch.flg_status)) icon_sch_status,
                   pk_schedule.g_icon_prefix || 'ExtendIcon' extend_icon,
                   pk_sr_visit.is_epis_registered(i_lang, sch.id_episode) AS flg_registered
              FROM schedule sch
             INNER JOIN sch_group schg
                ON sch.id_schedule = schg.id_schedule
             INNER JOIN sch_resource sr
                ON sch.id_schedule = sr.id_schedule
             INNER JOIN schedule_sr ss
                ON sch.id_schedule = ss.id_schedule
             INNER JOIN sch_consult_vacancy schcv
                ON sch.id_sch_consult_vacancy = schcv.id_sch_consult_vacancy
             WHERE sch.id_sch_consult_vacancy IN (SELECT column_value
                                                    FROM TABLE(l_vacancy_ids))
               AND sch.flg_status != g_canceled
            
            UNION ALL
            
            -- Free slots
            SELECT 3 regtype,
                   'SLOT' reg_type_str,
                   NULL icon_reg_type,
                   schcv.id_sch_consult_vacancy,
                   schcvos.id_sch_consult_vac_oris_slot,
                   pk_date_utils.date_daymonth_tsz(i_lang, schcvos.dt_begin, i_prof.institution, i_prof.software) daymonth,
                   pk_date_utils.date_year_tsz(i_lang, schcvos.dt_begin, i_prof.institution, i_prof.software) YEAR,
                   pk_date_utils.date_char_hour_tsz(i_lang, schcvos.dt_begin, i_prof.institution, i_prof.software) begin_hour,
                   pk_date_utils.date_char_hour_tsz(i_lang, schcvos.dt_end, i_prof.institution, i_prof.software) end_hour,
                   pk_date_utils.date_send_tsz(i_lang, schcvos.dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, schcvos.dt_end, i_prof) dt_end,
                   pk_date_utils.date_yearmonthday_tsz(i_lang, schcvos.dt_begin, i_prof.institution, i_prof.software) year_month_day,
                   pk_date_utils.date_send_tsz(i_lang, schcv.dt_begin_tstz, i_prof) begin_session,
                   schcv.id_room,
                   nvl((SELECT r.desc_room
                         FROM room r
                        WHERE r.id_room = schcv.id_room),
                       pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || schcv.id_room)) room_name,
                   get_id_dep_from_room(schcv.id_room) id_dep,
                   get_dep_name_from_room(i_lang, schcv.id_room) dep_name,
                   NULL id_patient,
                   NULL patient_name,
                   NULL pat_ndo,
                   NULL pat_nd_icon,
                   schcv.id_dep_clin_serv,
                   get_dep_clin_serv_name(i_lang, i_prof, schcv.id_dep_clin_serv, NULL) desc_dcs,
                   NULL id_schedule,
                   NULL surgery_name,
                   NULL id_professional,
                   NULL prof_name,
                   NULL id_episode,
                   NULL id_waiting_list,
                   'E' flg_color_session,
                   NULL color_dcs,
                   NULL vac_total_hours,
                   NULL vac_free_hours,
                   NULL flg_temporary,
                   NULL notif_status,
                   NULL notif_icon_status,
                   NULL sch_status,
                   NULL icon_sch_status,
                   pk_schedule.g_icon_prefix || 'ExtendIcon' extend_icon,
                   '' flg_registered
              FROM sch_consult_vacancy schcv
             INNER JOIN sch_consult_vac_oris_slot schcvos
                ON schcv.id_sch_consult_vacancy = schcvos.id_sch_consult_vacancy
             WHERE schcv.id_sch_consult_vacancy IN (SELECT column_value
                                                      FROM TABLE(l_vacancy_ids))
               AND schcv.dt_end_tstz - schcv.dt_begin_tstz != schcvos.dt_end - schcvos.dt_begin
            
             ORDER BY year_month_day, begin_session, room_name, id_sch_consult_vacancy, dt_begin, regtype;
    
        g_error := 'OPEN CURSOR';
        OPEN o_colors FOR
            SELECT sc.color_name, '0x' || sc.color_hex color_hex
              FROM sch_color sc
             WHERE sc.color_name IN ('EMPTY_TEXT_COLOR',
                                     'HALF_FULL_TEXT_COLOR',
                                     'FULL_TEXT_COLOR',
                                     'FULL_ICON_COLOR',
                                     'HALF_FULL_ICON_COLOR',
                                     'EMPTY_ICON_COLOR',
                                     'FULL_BACKGROUND_COLOR',
                                     'HALF_FULL_BACKGROUND_COLOR',
                                     'EMPTY_ORIS_BACKGROUND_COLOR');
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_listview_info);
            pk_types.open_my_cursor(o_colors);
            pk_date_utils.set_dst_time_check_on;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_listview_info;

    /**********************************************************************************************
    * API - insert one row on sch_consult_vac_oris_slot table
    *
    * @param id_sch_consult_vac_oris_in      sch_consult_vac_oris ID
    * @param id_sch_consult_vacancy_in       sch_consult_vacancy ID
    * @param id_physiatry_area_in            physiatry_area ID
    * @param dt_begin_tstz_in                begin date
    * @param dt_end_tstz_in                  end date
    * @param id_professional_in              professional ID
    * @param flg_status_in                   flag status
    * @param id_prof_created_in              created by
    * @param dt_created_in                   creating date
    * @param id_sch_consult_vac_oris_out     output parameter - new inserted id_sch_consult_vac_oris_slot
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION ins_sch_consult_vac_oris_slot
    (
        i_lang                     IN language.id_language%TYPE,
        id_sch_consult_vac_oris_in IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_in  IN sch_consult_vac_oris_slot.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        dt_begin_in                IN sch_consult_vac_oris_slot.dt_begin%TYPE DEFAULT NULL,
        dt_end_in                  IN sch_consult_vac_oris_slot.dt_end%TYPE DEFAULT NULL,
        --id_prof_created_in          IN sch_consult_vac_oris_slot.id_prof_created%TYPE DEFAULT NULL,
        --dt_created_in               IN sch_consult_vac_oris_slot.dt_created%TYPE DEFAULT NULL,
        id_sch_consult_vac_oris_out OUT sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INS_SCH_CONSULT_VAC_ORIS_SLOT';
    BEGIN
        g_error := 'INSERT INTO SCH_CONSULT_VAC_ORIS_SLOT';
        INSERT INTO sch_consult_vac_oris_slot
            (id_sch_consult_vac_oris_slot, id_sch_consult_vacancy, dt_begin, dt_end) --, id_prof_created, dt_created)
        VALUES
            (nvl(id_sch_consult_vac_oris_in, seq_sch_consult_vac_oris_slot.nextval),
             id_sch_consult_vacancy_in,
             dt_begin_in,
             dt_end_in) --,
        --id_prof_created_in,
        --dt_created_in)
        RETURNING id_sch_consult_vac_oris_slot INTO id_sch_consult_vac_oris_out;
    
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
        
    END ins_sch_consult_vac_oris_slot;

    /**********************************************************************************************
    * API - update one row on sch_consult_vac_oris_slot table by primary key
    *
    * @param id_sch_consult_vac_oris_in      sch_consult_vac_oris ID
    * @param id_sch_consult_vacancy_in       sch_consult_vacancy ID
    * @param id_sch_consult_vacancy_nin      boolean flag to accept null values    
    * @param dt_begin_in                     begin date
    * @param dt_begin_nin                    boolean flag to accept null values   
    * @param dt_end_in                       end date
    * @param dt_end_nin                      boolean flag to accept null values
    * @param id_professional_in              professional ID
    * @param id_professional_nin             boolean flag to accept null values
    * @param flg_status_in                   flag status
    * @param flg_status_nin                  boolean flag to accept null values
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION upd_sch_consult_vac_oris_slot
    (
        i_lang                     IN language.id_language%TYPE,
        id_sch_consult_vac_oris_in IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_in  IN sch_consult_vac_oris_slot.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        id_sch_consult_vacancy_nin IN BOOLEAN := TRUE,
        dt_begin_in                IN sch_consult_vac_oris_slot.dt_begin%TYPE DEFAULT NULL,
        dt_begin_nin               IN BOOLEAN := TRUE,
        dt_end_in                  IN sch_consult_vac_oris_slot.dt_end%TYPE DEFAULT NULL,
        dt_end_nin                 IN BOOLEAN := TRUE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                VARCHAR2(30) := 'UPD_SCH_CONSULT_VAC_ORIS_SLOT';
        l_id_sch_consult_vacancy_n NUMBER(1);
        l_dt_begin_n               NUMBER(1);
        l_dt_end_n                 NUMBER(1);
    BEGIN
        g_error                    := 'CONVERT BOOLEAN TO INTEGER';
        l_id_sch_consult_vacancy_n := sys.diutil.bool_to_int(id_sch_consult_vacancy_nin);
        l_dt_begin_n               := sys.diutil.bool_to_int(dt_begin_nin);
        l_dt_end_n                 := sys.diutil.bool_to_int(dt_end_nin);
    
        g_error := 'UPDATE SCH_CONSULT_VAC_ORIS_SLOT';
        UPDATE sch_consult_vac_oris_slot
           SET id_sch_consult_vacancy = CASE
                                             WHEN l_id_sch_consult_vacancy_n = 1 THEN
                                              nvl(id_sch_consult_vacancy_in, id_sch_consult_vacancy)
                                             ELSE
                                              id_sch_consult_vacancy_in
                                         END,
               dt_begin = CASE
                               WHEN l_dt_begin_n = 1 THEN
                                nvl(dt_begin_in, dt_begin)
                               ELSE
                                dt_begin_in
                           END,
               dt_end = CASE
                             WHEN l_dt_end_n = 1 THEN
                              nvl(dt_end_in, dt_end)
                             ELSE
                              dt_end_in
                         END
         WHERE id_sch_consult_vac_oris_slot = id_sch_consult_vac_oris_in;
    
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
        
    END upd_sch_consult_vac_oris_slot;

    /**********************************************************************************************
    * API - insert one row on schedule_sr table
    *
    * @param i_lang                       language id
    * @param id_schedule_sr_in            new pk id. usually null as it is sorted out by the sequence
    * @param  ...                         ... all schedule_sr columns here
    * @param o_error                      error stuff
    *
    * @return                                success / fail
    *
    * @author   Telmo
    * @version  2.5
    * @since    13-04-2009
    **********************************************************************************************/
    FUNCTION ins_schedule_sr
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        id_schedule_sr_in         IN schedule_sr.id_schedule_sr%TYPE DEFAULT NULL,
        id_sched_sr_parent_in     IN schedule_sr.id_sched_sr_parent%TYPE DEFAULT NULL,
        id_schedule_in            IN schedule_sr.id_schedule%TYPE DEFAULT NULL,
        id_episode_in             IN schedule_sr.id_episode%TYPE DEFAULT NULL,
        id_patient_in             IN schedule_sr.id_patient%TYPE DEFAULT NULL,
        duration_in               IN schedule_sr.duration%TYPE DEFAULT NULL,
        id_diagnosis_in           IN schedule_sr.id_diagnosis%TYPE DEFAULT NULL,
        id_speciality_in          IN schedule_sr.id_speciality%TYPE DEFAULT NULL,
        flg_status_in             IN schedule_sr.flg_status%TYPE DEFAULT NULL,
        flg_sched_in              IN schedule_sr.flg_sched%TYPE DEFAULT NULL,
        id_dept_dest_in           IN schedule_sr.id_dept_dest%TYPE DEFAULT NULL,
        prev_recovery_time_in     IN schedule_sr.prev_recovery_time%TYPE DEFAULT NULL,
        id_sr_cancel_reason_in    IN schedule_sr.id_sr_cancel_reason%TYPE DEFAULT NULL,
        id_prof_cancel_in         IN schedule_sr.id_prof_cancel%TYPE DEFAULT NULL,
        notes_cancel_in           IN schedule_sr.notes_cancel%TYPE DEFAULT NULL,
        id_prof_reg_in            IN schedule_sr.id_prof_reg%TYPE DEFAULT NULL,
        id_institution_in         IN schedule_sr.id_institution%TYPE DEFAULT NULL,
        adw_last_update_in        IN schedule_sr.adw_last_update%TYPE DEFAULT NULL,
        dt_target_tstz_in         IN schedule_sr.dt_target_tstz%TYPE DEFAULT NULL,
        dt_interv_preview_tstz_in IN schedule_sr.dt_interv_preview_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_in         IN schedule_sr.dt_cancel_tstz%TYPE DEFAULT NULL,
        id_waiting_list_in        IN schedule_sr.id_waiting_list%TYPE DEFAULT NULL,
        flg_temporary_in          IN schedule_sr.flg_temporary%TYPE DEFAULT NULL,
        icu_in                    IN schedule_sr.icu%TYPE DEFAULT NULL,
        --id_pos_status_in          IN schedule_sr.id_sr_pos_status%TYPE DEFAULT NULL,
        notes_in           IN schedule_sr.notes%TYPE DEFAULT NULL,
        id_schedule_sr_out OUT schedule_sr.id_schedule_sr%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'INS_SCHEDULE_SR';
        l_schedule_sr schedule_sr%ROWTYPE;
        l_rowids      table_varchar;
    BEGIN
        --
        IF id_schedule_sr_in IS NOT NULL
        THEN
            l_schedule_sr.id_schedule_sr := id_schedule_sr_in;
        ELSE
            l_schedule_sr.id_schedule_sr := ts_schedule_sr.next_key;
        END IF;
    
        --
        l_schedule_sr.id_sched_sr_parent     := id_sched_sr_parent_in;
        l_schedule_sr.id_schedule            := id_schedule_in;
        l_schedule_sr.id_episode             := id_episode_in;
        l_schedule_sr.id_patient             := id_patient_in;
        l_schedule_sr.duration               := duration_in;
        l_schedule_sr.id_diagnosis           := id_diagnosis_in;
        l_schedule_sr.id_speciality          := id_speciality_in;
        l_schedule_sr.flg_status             := flg_status_in;
        l_schedule_sr.flg_sched              := flg_sched_in;
        l_schedule_sr.id_dept_dest           := id_dept_dest_in;
        l_schedule_sr.prev_recovery_time     := prev_recovery_time_in;
        l_schedule_sr.id_sr_cancel_reason    := id_sr_cancel_reason_in;
        l_schedule_sr.id_prof_cancel         := id_prof_cancel_in;
        l_schedule_sr.notes_cancel           := notes_cancel_in;
        l_schedule_sr.id_prof_reg            := id_prof_reg_in;
        l_schedule_sr.id_institution         := id_institution_in;
        l_schedule_sr.adw_last_update        := adw_last_update_in;
        l_schedule_sr.dt_target_tstz         := dt_target_tstz_in;
        l_schedule_sr.dt_interv_preview_tstz := dt_interv_preview_tstz_in;
        l_schedule_sr.dt_cancel_tstz         := dt_cancel_tstz_in;
        l_schedule_sr.id_waiting_list        := id_waiting_list_in;
        l_schedule_sr.flg_temporary          := flg_temporary_in;
        l_schedule_sr.icu                    := icu_in;
        l_schedule_sr.notes                  := notes_in;
    
        --
        g_error  := 'CALL TS_SCHEDULE_SR.INS WITH ID_SCHEDULE_SR = ' || l_schedule_sr.id_schedule_sr;
        l_rowids := table_varchar();
        ts_schedule_sr.ins(rec_in => l_schedule_sr, rows_out => l_rowids);
    
        g_error := 'PROCESS INSERT WITH ID_SCHEDULE_SR ' || l_schedule_sr.id_schedule_sr;
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'SCHEDULE_SR', l_rowids, o_error);
    
        id_schedule_sr_out := l_schedule_sr.id_schedule_sr;
    
        --
        IF l_schedule_sr.id_episode IS NOT NULL
        THEN
            l_rowids := table_varchar();
            ts_epis_info.upd(id_episode_in     => l_schedule_sr.id_episode,
                             id_schedule_sr_in => l_schedule_sr.id_schedule_sr,
                             rows_out          => l_rowids);
            g_error := 'PROCESS UPDATE WITH ID_SCHEDULE_SR ' || l_schedule_sr.id_schedule_sr;
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'EPIS_INFO',
                                          l_rowids,
                                          o_error,
                                          table_varchar('ID_SCHEDULE_SR'));
        END IF;
    
        --
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
    END ins_schedule_sr;

    /**********************************************************************************************
    * API - update one row in schedule_sr table by primary key
    *
    * @param id_sch_consult_vac_oris_in      sch_consult_vac_oris ID
    * @param o_error                         descripton error
    *
    * @return                                success / fail
    *
    * @author   Telmo
    * @version  2.5
    * @since    13-04-2009
    **********************************************************************************************/
    FUNCTION upd_schedule_sr
    (
        i_lang                     IN language.id_language%TYPE,
        id_schedule_sr_in          IN schedule_sr.id_schedule_sr%TYPE DEFAULT NULL,
        id_sched_sr_parent_in      IN schedule_sr.id_sched_sr_parent%TYPE DEFAULT NULL,
        id_sched_sr_parent_nin     IN BOOLEAN := TRUE,
        id_schedule_in             IN schedule_sr.id_schedule%TYPE DEFAULT NULL,
        id_schedule_nin            IN BOOLEAN := TRUE,
        id_episode_in              IN schedule_sr.id_episode%TYPE DEFAULT NULL,
        id_episode_nin             IN BOOLEAN := TRUE,
        id_patient_in              IN schedule_sr.id_patient%TYPE DEFAULT NULL,
        id_patient_nin             IN BOOLEAN := TRUE,
        duration_in                IN schedule_sr.duration%TYPE DEFAULT NULL,
        duration_nin               IN BOOLEAN := TRUE,
        id_diagnosis_in            IN schedule_sr.id_diagnosis%TYPE DEFAULT NULL,
        id_diagnosis_nin           IN BOOLEAN := TRUE,
        id_speciality_in           IN schedule_sr.id_speciality%TYPE DEFAULT NULL,
        id_speciality_nin          IN BOOLEAN := TRUE,
        flg_status_in              IN schedule_sr.flg_status%TYPE DEFAULT NULL,
        flg_status_nin             IN BOOLEAN := TRUE,
        flg_sched_in               IN schedule_sr.flg_sched%TYPE DEFAULT NULL,
        flg_sched_nin              IN BOOLEAN := TRUE,
        id_dept_dest_in            IN schedule_sr.id_dept_dest%TYPE DEFAULT NULL,
        id_dept_dest_nin           IN BOOLEAN := TRUE,
        prev_recovery_time_in      IN schedule_sr.prev_recovery_time%TYPE DEFAULT NULL,
        prev_recovery_time_nin     IN BOOLEAN := TRUE,
        id_sr_cancel_reason_in     IN schedule_sr.id_sr_cancel_reason%TYPE DEFAULT NULL,
        id_sr_cancel_reason_nin    IN BOOLEAN := TRUE,
        id_prof_cancel_in          IN schedule_sr.id_prof_cancel%TYPE DEFAULT NULL,
        id_prof_cancel_nin         IN BOOLEAN := TRUE,
        notes_cancel_in            IN schedule_sr.notes_cancel%TYPE DEFAULT NULL,
        notes_cancel_nin           IN BOOLEAN := TRUE,
        id_prof_reg_in             IN schedule_sr.id_prof_reg%TYPE DEFAULT NULL,
        id_prof_reg_nin            IN BOOLEAN := TRUE,
        id_institution_in          IN schedule_sr.id_institution%TYPE DEFAULT NULL,
        id_institution_nin         IN BOOLEAN := TRUE,
        adw_last_update_in         IN schedule_sr.adw_last_update%TYPE DEFAULT NULL,
        adw_last_update_nin        IN BOOLEAN := TRUE,
        dt_target_tstz_in          IN schedule_sr.dt_target_tstz%TYPE DEFAULT NULL,
        dt_target_tstz_nin         IN BOOLEAN := TRUE,
        dt_interv_preview_tstz_in  IN schedule_sr.dt_interv_preview_tstz%TYPE DEFAULT NULL,
        dt_interv_preview_tstz_nin IN BOOLEAN := TRUE,
        dt_cancel_tstz_in          IN schedule_sr.dt_cancel_tstz%TYPE DEFAULT NULL,
        dt_cancel_tstz_nin         IN BOOLEAN := TRUE,
        id_waiting_list_in         IN schedule_sr.id_waiting_list%TYPE DEFAULT NULL,
        id_waiting_list_nin        IN BOOLEAN := TRUE,
        flg_temporary_in           IN schedule_sr.flg_temporary%TYPE DEFAULT NULL,
        flg_temporary_nin          IN BOOLEAN := TRUE,
        icu_in                     IN schedule_sr.icu%TYPE DEFAULT NULL,
        icu_nin                    IN BOOLEAN := TRUE,
        notes_in                   IN schedule_sr.notes%TYPE DEFAULT NULL,
        notes_nin                  IN BOOLEAN := TRUE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                  VARCHAR2(30) := 'UPD_SCHEDULE_SR';
        l_id_sched_sr_parent_nin     NUMBER(1);
        l_id_schedule_nin            NUMBER(1);
        l_id_episode_nin             NUMBER(1);
        l_id_patient_nin             NUMBER(1);
        l_duration_nin               NUMBER(1);
        l_id_diagnosis_nin           NUMBER(1);
        l_id_speciality_nin          NUMBER(1);
        l_flg_status_nin             NUMBER(1);
        l_flg_sched_nin              NUMBER(1);
        l_id_dept_dest_nin           NUMBER(1);
        l_prev_recovery_time_nin     NUMBER(1);
        l_id_sr_cancel_reason_nin    NUMBER(1);
        l_id_prof_cancel_nin         NUMBER(1);
        l_notes_cancel_nin           NUMBER(1);
        l_id_prof_reg_nin            NUMBER(1);
        l_id_institution_nin         NUMBER(1);
        l_adw_last_update_nin        NUMBER(1);
        l_dt_target_tstz_nin         NUMBER(1);
        l_dt_interv_preview_tstz_nin NUMBER(1);
        l_dt_cancel_tstz_nin         NUMBER(1);
        l_id_waiting_list_nin        NUMBER(1);
        l_flg_temporary_nin          NUMBER(1);
        l_icu_nin                    NUMBER(1);
        l_id_pos_status_nin          NUMBER(1);
        l_notes_nin                  NUMBER(1);
    
        l_rowids table_varchar;
    BEGIN
        g_error                      := 'CONVERT BOOLEAN TO INTEGER';
        l_id_sched_sr_parent_nin     := sys.diutil.bool_to_int(id_sched_sr_parent_nin);
        l_id_schedule_nin            := sys.diutil.bool_to_int(id_schedule_nin);
        l_id_episode_nin             := sys.diutil.bool_to_int(id_episode_nin);
        l_id_patient_nin             := sys.diutil.bool_to_int(id_patient_nin);
        l_duration_nin               := sys.diutil.bool_to_int(duration_nin);
        l_id_diagnosis_nin           := sys.diutil.bool_to_int(id_diagnosis_nin);
        l_id_speciality_nin          := sys.diutil.bool_to_int(id_speciality_nin);
        l_flg_status_nin             := sys.diutil.bool_to_int(flg_status_nin);
        l_flg_sched_nin              := sys.diutil.bool_to_int(flg_sched_nin);
        l_id_dept_dest_nin           := sys.diutil.bool_to_int(id_dept_dest_nin);
        l_prev_recovery_time_nin     := sys.diutil.bool_to_int(prev_recovery_time_nin);
        l_id_sr_cancel_reason_nin    := sys.diutil.bool_to_int(id_sr_cancel_reason_nin);
        l_id_prof_cancel_nin         := sys.diutil.bool_to_int(id_prof_cancel_nin);
        l_notes_cancel_nin           := sys.diutil.bool_to_int(notes_cancel_nin);
        l_id_prof_reg_nin            := sys.diutil.bool_to_int(id_prof_reg_nin);
        l_id_institution_nin         := sys.diutil.bool_to_int(id_institution_nin);
        l_adw_last_update_nin        := sys.diutil.bool_to_int(adw_last_update_nin);
        l_dt_target_tstz_nin         := sys.diutil.bool_to_int(dt_target_tstz_nin);
        l_dt_interv_preview_tstz_nin := sys.diutil.bool_to_int(dt_interv_preview_tstz_nin);
        l_dt_cancel_tstz_nin         := sys.diutil.bool_to_int(dt_cancel_tstz_nin);
        l_id_waiting_list_nin        := sys.diutil.bool_to_int(id_waiting_list_nin);
        l_flg_temporary_nin          := sys.diutil.bool_to_int(flg_temporary_nin);
        l_icu_nin                    := sys.diutil.bool_to_int(icu_nin);
        l_notes_nin                  := sys.diutil.bool_to_int(notes_nin);
    
        g_error  := 'UPDATE SCHEDULE_SR';
        l_rowids := table_varchar();
        ts_schedule_sr.upd(id_sched_sr_parent_in      => id_sched_sr_parent_in,
                           id_sched_sr_parent_nin     => CASE
                                                             WHEN l_id_sched_sr_parent_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_schedule_in             => id_schedule_in,
                           id_schedule_nin            => CASE
                                                             WHEN l_id_schedule_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_episode_in              => id_episode_in,
                           id_episode_nin             => CASE
                                                             WHEN l_id_episode_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_patient_in              => id_patient_in,
                           id_patient_nin             => CASE
                                                             WHEN l_id_patient_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           duration_in                => duration_in,
                           duration_nin               => CASE
                                                             WHEN l_duration_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_diagnosis_in            => id_diagnosis_in,
                           id_diagnosis_nin           => CASE
                                                             WHEN l_id_diagnosis_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_speciality_in           => id_speciality_in,
                           id_speciality_nin          => CASE
                                                             WHEN l_id_speciality_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           flg_status_in              => flg_status_in,
                           flg_status_nin             => CASE
                                                             WHEN l_flg_status_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           flg_sched_in               => flg_sched_in,
                           flg_sched_nin              => CASE
                                                             WHEN l_flg_sched_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_dept_dest_in            => id_dept_dest_in,
                           id_dept_dest_nin           => CASE
                                                             WHEN l_id_dept_dest_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           prev_recovery_time_in      => prev_recovery_time_in,
                           prev_recovery_time_nin     => CASE
                                                             WHEN l_prev_recovery_time_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_sr_cancel_reason_in     => id_sr_cancel_reason_in,
                           id_sr_cancel_reason_nin    => CASE
                                                             WHEN l_id_sr_cancel_reason_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_prof_cancel_in          => id_prof_cancel_in,
                           id_prof_cancel_nin         => CASE
                                                             WHEN l_id_prof_cancel_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           notes_cancel_in            => notes_cancel_in,
                           notes_cancel_nin           => CASE
                                                             WHEN l_notes_cancel_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_prof_reg_in             => id_prof_reg_in,
                           id_prof_reg_nin            => CASE
                                                             WHEN l_id_prof_reg_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_institution_in          => id_institution_in,
                           id_institution_nin         => CASE
                                                             WHEN l_id_institution_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           dt_target_tstz_in          => dt_target_tstz_in,
                           dt_target_tstz_nin         => CASE
                                                             WHEN l_dt_target_tstz_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           dt_interv_preview_tstz_in  => dt_interv_preview_tstz_in,
                           dt_interv_preview_tstz_nin => CASE
                                                             WHEN l_dt_interv_preview_tstz_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           dt_cancel_tstz_in          => dt_cancel_tstz_in,
                           dt_cancel_tstz_nin         => CASE
                                                             WHEN l_dt_cancel_tstz_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           id_waiting_list_in         => id_waiting_list_in,
                           id_waiting_list_nin        => CASE
                                                             WHEN l_id_waiting_list_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           flg_temporary_in           => flg_temporary_in,
                           flg_temporary_nin          => CASE
                                                             WHEN l_flg_temporary_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           icu_in                     => icu_in,
                           icu_nin                    => CASE
                                                             WHEN l_icu_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           notes_in                   => notes_in,
                           notes_nin                  => CASE
                                                             WHEN l_notes_nin = 1 THEN
                                                              TRUE
                                                             ELSE
                                                              FALSE
                                                         END,
                           where_in                   => 'id_schedule_sr = ' || id_schedule_sr_in,
                           rows_out                   => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => NULL,
                                      i_table_name => 'SCHEDULE_SR',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
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
    END upd_schedule_sr;

    /********************************************************************************************
    * This function determine and inserts on table sch_consult_vac_oris_slot the free slots for a
    * sch_consult_vacancy ID 
    *
    * @param i_lang                          language ID
    * @param i_prof                          profissional type (id + institution + software)
    * @param i_id_sch_consult_vacancy        sch_consult_vacancy ID
    * @param i_id_prof_created               professional ID
    * @param o_error                         error message  
    *
    * @return                                success / fail   
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/03/31
    ********************************************************************************************/
    FUNCTION create_slots
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_sch_consult_vacancy IS
            SELECT dt_begin_tstz, dt_end_tstz
              FROM sch_consult_vacancy
             WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy;
    
        CURSOR c_schedule IS
            SELECT dt_begin_tstz, dt_end_tstz
              FROM schedule
             WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy
               AND schedule.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_sr
               AND schedule.flg_status != g_canceled
             ORDER BY dt_begin_tstz ASC;
    
        l_func_name         VARCHAR2(30) := 'CREATE_SLOTS';
        l_dt_begin_scv      sch_consult_vacancy.dt_begin_tstz%TYPE;
        l_dt_end_scv        sch_consult_vacancy.dt_end_tstz%TYPE;
        l_dt_aux            sch_consult_vacancy.dt_end_tstz%TYPE;
        l_min_slot_interval NUMBER;
        l_dummy             sch_consult_vac_oris_slot.id_sch_consult_vacancy%TYPE;
    
        l_tab_dt_begin table_timestamp_tz;
        l_tab_dt_end   table_timestamp_tz;
    
    BEGIN
        -- Get configuration for minimum time for free slots
        g_error := 'GET CONFIGURATION FOR MINIMUM TIME FOR FREE SLOTS';
        BEGIN
            l_min_slot_interval := nvl(to_number(pk_sysconfig.get_config(g_sch_min_slot_interval, i_prof)), 0);
        EXCEPTION
            WHEN OTHERS THEN
                l_min_slot_interval := 0;
        END;
    
        -- Read dt_begin and dt_end from sch_consult_vacancy
        g_error := 'OPEN CURSOR C_SCH_CONSULT_VACANCY';
        OPEN c_sch_consult_vacancy;
        FETCH c_sch_consult_vacancy
            INTO l_dt_begin_scv, l_dt_end_scv;
        g_found := c_sch_consult_vacancy%FOUND;
        CLOSE c_sch_consult_vacancy;
    
        IF NOT g_found
           OR l_dt_begin_scv IS NULL
           OR l_dt_end_scv IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        -- Delete from sch_consult_vac_oris_slot
        g_error := 'DELETE SCH_CONSULT_VAC_ORIS_SLOT';
        DELETE FROM sch_consult_vac_oris_slot
         WHERE id_sch_consult_vacancy = i_id_sch_consult_vacancy;
    
        -- Searching free slots
        l_dt_aux := l_dt_begin_scv;
    
        g_error := 'OPEN CURSOR C_SCHEDULE';
        OPEN c_schedule;
        FETCH c_schedule BULK COLLECT
            INTO l_tab_dt_begin, l_tab_dt_end;
        CLOSE c_schedule;
    
        -- Iteration between begin and end slot dates
        g_error := 'LOOP PK_SCHEDULE_ORIS.INS_SCH_CONSULT_VAC_ORIS_SLOT';
        FOR idx IN 1 .. l_tab_dt_begin.count
        LOOP
        
            IF (pk_date_utils.get_timestamp_diff(l_tab_dt_begin(idx), l_dt_aux) * 1440) > l_min_slot_interval
            THEN
                IF NOT ins_sch_consult_vac_oris_slot(i_lang                    => i_lang,
                                                     id_sch_consult_vacancy_in => i_id_sch_consult_vacancy,
                                                     dt_begin_in               => l_dt_aux,
                                                     dt_end_in                 => l_tab_dt_begin(idx),
                                                     --id_prof_created_in          => i_prof.id,
                                                     --dt_created_in               => current_timestamp,
                                                     id_sch_consult_vac_oris_out => l_dummy,
                                                     o_error                     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
            l_dt_aux := l_tab_dt_end(idx);
        END LOOP;
    
        -- Time difference between last schedule end date and vacancy end date
        g_error := 'LAST CALL PK_SCHEDULE_ORIS.INS_SCH_CONSULT_VAC_ORIS_SLOT';
        IF (pk_date_utils.get_timestamp_diff(l_dt_end_scv, l_dt_aux) * 1440) > l_min_slot_interval
        THEN
            IF NOT ins_sch_consult_vac_oris_slot(i_lang                    => i_lang,
                                                 id_sch_consult_vacancy_in => i_id_sch_consult_vacancy,
                                                 dt_begin_in               => l_dt_aux,
                                                 dt_end_in                 => l_dt_end_scv,
                                                 --id_prof_created_in          => i_prof.id,
                                                 --dt_created_in               => current_timestamp,
                                                 id_sch_consult_vac_oris_out => l_dummy,
                                                 o_error                     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
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
        
    END create_slots;

    /**********************************************************************************************
    * API - Insert record on SCH_CLIPBOARD
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule ID
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION ins_sch_clipboard
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'INS_SCH_CLIPBOARD';
    BEGIN
        g_error := 'INSERT ON SCH_CLIPBOARD';
    
        INSERT INTO sch_clipboard
            (id_schedule, id_prof_created, dt_creation)
        VALUES
            (i_id_schedule, i_prof.id, current_timestamp);
    
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
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END ins_sch_clipboard;

    /**********************************************************************************************
    * API - Delete record from SCH_CLIPBOARD
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule ID
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION del_sch_clipboard
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'DEL_SCH_CLIPBOARD';
    BEGIN
        g_error := 'DELETE FROM SCH_CLIPBOARD';
    
        DELETE sch_clipboard
         WHERE id_schedule = i_id_schedule
           AND id_prof_created = i_prof.id;
    
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
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END del_sch_clipboard;

    /**********************************************************************************************
    * Confirm temporary to permanent schedules
    *
    * @i_lang                                Language ID
    * @i_prof                                Profissional array
    * @i_tab_id_schedule                     Schedule IDs Table to confirm
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5
    * @since                                 2009/03/31
    **********************************************************************************************/
    FUNCTION confirm_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'CONFIRM_SCHEDULES';
        l_schedule_sr_tc ts_schedule_sr.schedule_sr_tc;
        l_rowids         table_varchar;
    
    BEGIN
        g_error := 'UPDATE SCHEDULE_SR TEMPORARY FLAG';
        SELECT *
          BULK COLLECT
          INTO l_schedule_sr_tc
          FROM schedule_sr
         WHERE id_schedule IN (SELECT column_value
                                 FROM TABLE(i_tab_id_schedule));
    
        FOR j IN 1 .. l_schedule_sr_tc.count
        LOOP
            l_schedule_sr_tc(j).flg_temporary := g_no;
        END LOOP;
    
        IF l_schedule_sr_tc.count > 0
        THEN
            g_error  := 'UPDATE SCHEDULE_SR';
            l_rowids := table_varchar();
            ts_schedule_sr.upd(col_in => l_schedule_sr_tc, ignore_if_null_in => FALSE, rows_out => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'SCHEDULE_SR',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_TEMPORARY'));
        END IF;
    
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
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
        
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END confirm_schedules;

    /**
    * Cancel an ORIS schedule.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_schedule        The schedule id to be canceled
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes
    * @param o_error              Error message if something goes wrong
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_id_sch_consult_vac sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_id_wl              schedule_sr.id_waiting_list%TYPE;
    
        --
        l_id_patient          patient.id_patient%TYPE;
        l_dpb                 waiting_list.dt_dpb%TYPE;
        l_dpa                 waiting_list.dt_dpa%TYPE;
        l_flg_type            waiting_list.flg_type%TYPE;
        l_flg_status          waiting_list.flg_status%TYPE;
        l_dt_surgery          waiting_list.dt_surgery%TYPE;
        l_min_inform_time     waiting_list.min_inform_time%TYPE;
        l_id_urg_level        waiting_list.id_wtl_urg_level%TYPE;
        l_id_external_request waiting_list.id_external_request%TYPE;
        l_id_episode          schedule.id_episode%TYPE;
    BEGIN
    
        -- get schedule data
        g_error := 'GET VACANCY ID';
        SELECT s.id_sch_consult_vacancy, ssr.id_waiting_list
          INTO l_id_sch_consult_vac, l_id_wl
          FROM schedule s, schedule_sr ssr
         WHERE s.id_schedule = ssr.id_schedule
           AND s.id_schedule = i_id_schedule;
    
        g_error := 'CALL PK_SCHEDULE_COMMON.CANCEL_SCHEDULE';
        IF NOT pk_schedule_common.cancel_schedule(i_lang             => i_lang,
                                                  i_id_professional  => i_prof.id,
                                                  i_id_software      => i_prof.software,
                                                  i_id_schedule      => i_id_schedule,
                                                  i_id_cancel_reason => i_id_cancel_reason,
                                                  i_cancel_notes     => i_cancel_notes,
                                                  i_ignore_vacancies => FALSE,
                                                  o_error            => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL CREATE_SLOTS';
        IF NOT pk_schedule_oris.create_slots(i_lang                   => i_lang,
                                             i_prof                   => i_prof,
                                             i_id_sch_consult_vacancy => l_id_sch_consult_vac,
                                             o_error                  => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'DELETE FROM SCH_CLIPBOARD';
        DELETE FROM sch_clipboard
         WHERE id_schedule = i_id_schedule;
    
        g_error := 'CALL PK_WTL_PBL_CORE.CANCEL_SCHEDULE';
        IF NOT pk_wtl_pbl_core.cancel_schedule(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_wtlist   => l_id_wl,
                                               i_id_schedule => i_id_schedule,
                                               o_error       => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --update referral status
        g_error := 'CALL PK_WTL_PBL_CORE.GET_DATA';
        IF NOT pk_wtl_pbl_core.get_data(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_waiting_list     => l_id_wl,
                                        o_id_patient          => l_id_patient,
                                        o_flg_type            => l_flg_type,
                                        o_flg_status          => l_flg_status,
                                        o_dpb                 => l_dpb,
                                        o_dpa                 => l_dpa,
                                        o_dt_surgery          => l_dt_surgery,
                                        o_min_inform_time     => l_min_inform_time,
                                        o_id_urgency_lev      => l_id_urg_level,
                                        o_id_external_request => l_id_external_request,
                                        o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --update referral status
        IF (l_id_external_request IS NOT NULL)
        THEN
            g_error := 'GET I_ID_EPISODE ';
            SELECT s.id_episode
              INTO l_id_episode
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule;
        
            g_error := 'CALL PK_REF_EXT_SYS.CANCEL_REF_SCHEDULE with id_external_request: ' || l_id_external_request;
            IF NOT pk_ref_ext_sys.cancel_ref_schedule(i_lang     => i_lang,
                                                      i_prof     => i_prof,
                                                      i_id_ref   => l_id_external_request,
                                                      i_schedule => i_id_schedule,
                                                      i_notes    => NULL,
                                                      o_error    => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
    
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
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_schedule;

    /**
    * Cancel a set of ORIS schedules.
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_schedule                  Schedule ID
    * @param i_id_cancel_reason             Cancel reason
    * @param i_cancel_notes                 Cancel notes
    * @param o_error                        Error message if something goes wrong
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    */
    FUNCTION cancel_schedules
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN table_number,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CANCEL_SCHEDULES';
        o_list_schedules table_number;
    
    BEGIN
    
        g_error := 'CANCEL each schedule';
        IF (i_id_schedule.count > 0)
        THEN
            FOR i IN i_id_schedule.first .. i_id_schedule.last
            LOOP
                IF NOT cancel_schedule(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_schedule      => i_id_schedule(i),
                                       i_id_cancel_reason => i_id_cancel_reason,
                                       i_cancel_notes     => i_cancel_notes,
                                       o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
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
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_schedules;

    /**
    * returns list of surgery departments for specified institution.
    *
    * @param i_lang     language id
    * @param i_id_inst  institution specified
    * @param o_dep_list results
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Telmo
    * @version 2.5
    * @date    02-04-2009
    */
    FUNCTION get_sr_dep_list
    (
        i_lang     IN language.id_language%TYPE,
        i_id_inst  IN institution.id_institution%TYPE,
        o_dep_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SR_DEP_LIST';
        l_message   sys_message.desc_message%TYPE;
        l_linecount PLS_INTEGER;
    BEGIN
        g_error := 'GET DEPARTMENT COUNT';
        SELECT COUNT(1)
          INTO l_linecount
          FROM department dt
          JOIN dept d
            ON dt.id_dept = d.id_dept
         WHERE flg_type = g_surgery_dep_type
           AND d.id_institution = i_id_inst
           AND d.flg_available = g_yes;
    
        -- get sys_message for the output option 'Todos'
        IF NOT pk_schedule.get_validation_msgs(i_lang         => i_lang,
                                               i_code_msg     => g_msg_all_deps,
                                               i_pkg_name     => g_package_name,
                                               i_replacements => table_varchar(l_linecount),
                                               o_message      => l_message,
                                               o_error        => o_error)
        THEN
            pk_types.open_my_cursor(o_dep_list);
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN cursor';
        OPEN o_dep_list FOR
            SELECT pk_schedule.g_all data, nvl(l_message, ' ') desc_dep, g_yes flg_select, NULL abbr, 1 order_field
              FROM dual
            UNION
            SELECT dt.id_department,
                   pk_translation.get_translation(i_lang, dt.code_department),
                   g_no,
                   dt.abbreviation,
                   9 order_field
              FROM department dt
              JOIN dept d
                ON dt.id_dept = d.id_dept
             WHERE flg_type = 'S'
               AND d.id_institution = i_id_inst
               AND d.flg_available = g_yes
             ORDER BY order_field, desc_dep;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dep_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            -- If function called by FLASH
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sr_dep_list;

    /**
    * returns list of rooms for specified department. 
    *
    * @param i_lang     language id
    * @param i_id_inst  institution specified
    * @param o_dep_list results
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Telmo
    * @version 2.5
    * @date    02-04-2009
    */
    FUNCTION get_sr_rooms
    (
        i_lang      IN language.id_language%TYPE,
        i_id_dep    IN department.id_department%TYPE,
        o_room_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SR_ROOMS';
        l_message   sys_message.desc_message%TYPE;
        l_linecount PLS_INTEGER;
    BEGIN
        -- get room count
        g_error := 'GET ROOM COUNT';
        SELECT COUNT(1)
          INTO l_linecount
          FROM room r
         WHERE r.id_department = i_id_dep
           AND r.flg_available = g_yes;
        -- get sys_message
        IF NOT pk_schedule.get_validation_msgs(i_lang         => i_lang,
                                               i_code_msg     => g_msg_all_rooms,
                                               i_pkg_name     => g_package_name,
                                               i_replacements => table_varchar(l_linecount),
                                               o_message      => l_message,
                                               o_error        => o_error)
        THEN
            pk_types.open_my_cursor(o_room_list);
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN cursor';
        OPEN o_room_list FOR
            SELECT pk_schedule.g_all data, nvl(l_message, ' ') desc_room, g_yes flg_select, NULL abbr, 1 order_field
              FROM dual
            UNION
            SELECT r.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)),
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)),
                   g_no,
                   9
              FROM room r
             WHERE r.id_department = i_id_dep
               AND r.flg_available = g_yes
             ORDER BY order_field, desc_room;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_room_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            -- If function called by FLASH
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_sr_rooms;

    /**
    * returns the surgery scheduling status
    *
    * @param i_lang     language id    
    * @param o_status   Cursor with the scheduling status    
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_scheduling_status
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCHEDULING_STATUS';
    BEGIN
        g_error := 'OPEN O_STATUS';
        OPEN o_status FOR
            SELECT to_char(g_temporary) data,
                   pk_message.get_message(i_lang, g_msg_temporary) label,
                   g_no flg_select,
                   2 order_field
              FROM dual
            UNION ALL
            SELECT to_char(g_final) data,
                   pk_message.get_message(i_lang, g_msg_final) label,
                   g_no flg_select,
                   3 order_field
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_status);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_scheduling_status;

    /**
    * returns the surgery scheduling status including the all status option.
    *
    * @param i_lang     language id        
    * @param o_status   Cursor with the scheduling status    
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    09-04-2009
    */
    FUNCTION get_all_scheduling_status
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ALL_SCHEDULING_STATUS';
    BEGIN
        g_error := 'OPEN o_status';
    
        OPEN o_status FOR
            SELECT to_char(g_all) data,
                   pk_message.get_message(i_lang, g_msg_all_status) label,
                   g_yes flg_select,
                   1 order_field
              FROM dual
            UNION ALL
            SELECT to_char(g_temporary) data,
                   pk_message.get_message(i_lang, g_msg_temporary) label,
                   g_no flg_select,
                   2 order_field
              FROM dual
            UNION ALL
            SELECT to_char(g_final) data,
                   pk_message.get_message(i_lang, g_msg_final) label,
                   g_no flg_select,
                   3 order_field
              FROM dual
            UNION ALL
            SELECT to_char(g_canceled) data,
                   pk_message.get_message(i_lang, g_msg_cancelled) label,
                   g_no flg_select,
                   4 order_field
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_status);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_scheduling_status;

    /**
    * returns profissional and dep_clin_serv associated to a vacancy
    *
    * @param i_lang              Language id
    * @param i_prof              Professional identification
    * @param i_id_sch_vacancy    Vacancy Identification
    * @param o_id_dep_clin_serv  Dep_clin_serv iedntification
    * @param o_prof_name_sign    Signature of the vacancy professional
    * @param o_prof_id           Identification of the vacancy professional
    * @param o_error             Error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_vacancy_details
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_vacancy   IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_id_dep_clin_serv OUT sch_consult_vacancy.id_dep_clin_serv%TYPE,
        o_prof_name_sign   OUT VARCHAR2,
        o_prof_id          OUT professional.id_professional%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_VACANCY_DETAILS';
    BEGIN
        g_error := 'GET VACANCY DETAILS';
        SELECT cv.id_dep_clin_serv,
               pr.id_professional,
               pk_prof_utils.get_name_signature(i_lang, i_prof, pr.id_professional)
          INTO o_id_dep_clin_serv, o_prof_id, o_prof_name_sign
          FROM sch_consult_vacancy cv
          LEFT JOIN professional pr
            ON cv.id_prof = pr.id_professional
         WHERE cv.id_sch_consult_vacancy = i_id_sch_vacancy;
    
        RETURN TRUE;
    EXCEPTION
        --WHEN no_data_found THEN            
        --RETURN TRUE;
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
    END get_vacancy_details;

    /**
    * return the default surgeon (that appears on the surgery scheduling edition)
    *
    * @param i_lang              Language id
    * @param i_prof              Professional identification
    * @param i_id_waiting_list   Waiting List ID
    * @param o_prof_name         Professional signature
    * @param o_prof_id           Professional ID    
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_request_surgeon
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_waiting_list  IN waiting_list.id_waiting_list%TYPE,
        o_prof_name        OUT VARCHAR2,
        o_prof_id          OUT professional.id_professional%TYPE,
        o_id_dep_clin_serv OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(30) := 'GET_REQUEST_SURGEON';
        l_professionals pk_wtl_pbl_core.t_rec_professionals;
        l_dcss          pk_wtl_pbl_core.t_rec_dcss;
    
        l_no_depclinserv EXCEPTION;
    BEGIN
        g_error := 'CALL PK_WTL_PBL_CORE.GET_PROFESSIONALS';
        IF (pk_wtl_pbl_core.get_professionals(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_waiting_list => i_id_waiting_list,
                                              i_id_episode      => NULL,
                                              i_flg_type        => g_sr_prof_type,
                                              i_all             => g_no,
                                              o_professionals   => l_professionals,
                                              o_error           => o_error))
        THEN
            IF (l_professionals.count > 0)
            THEN
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pr.id_professional), pr.id_professional
                  INTO o_prof_name, o_prof_id
                  FROM professional pr
                 WHERE pr.id_professional = l_professionals(1).id_prof;
            ELSE
                o_prof_id := -1;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_WTL_PBL_CORE.GET_DEP_CLIN_SERVS';
        IF (pk_wtl_pbl_core.get_dep_clin_servs(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_id_waiting_list => i_id_waiting_list,
                                               i_id_episode      => NULL,
                                               i_flg_type        => g_sr_specialty,
                                               i_all             => g_no,
                                               o_dcs             => l_dcss,
                                               o_error           => o_error))
        THEN
            IF (l_dcss.count > 0)
            THEN
                o_id_dep_clin_serv := l_dcss(1).id_dep_clin_serv;
            ELSE
                -- the specialty (dep_clin_serv) is a mandatory field in the surgery request
                RAISE l_no_depclinserv;
            END IF;
        ELSE
            RETURN FALSE;
        END IF;
    
        /*o_id_dep_clin_serv := 2;
        o_prof_id          := -1;*/
    
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
    END get_request_surgeon;

    /**
    * return the default surgeon (that appears on the surgery scheduling edition)
    * according to the next rules:    
    * 1- Se existir cirurgião (admiting phisitian) na WL (waiting list) é este que aparece quando vai agendar. 
    *            A lista de cirurgiões é os da especialidade que vem da waiting list.
    * 2- Se não existir na WL e existir na sessão fica o da sessão. A lista de cirurgiões é os da especialidade que vem da WL. 
    * 3- Se não tiver nenhum é preenchido pelo utilizador no campo respectivo. 
    *              A lista de cirurgiões é os da especialidade que vem da waiting list. 
    *
    * @param i_lang              Language id
    * @param i_prof              Professional identification
    * @param i_id_sch_vacancy    Vacancy Identification
    * @param i_id_waiting_list   Waiting List Identification
    * @param o_id_dep_clin_serv  Dep_clin_serv identification
    * @param o_prof_name_sign    Default Surgeon name signature
    * @param o_prof_id           Default Surgeon id
    * @param o_error             error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_default_surgeon
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_vacancy   IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_waiting_list  IN waiting_list.id_waiting_list%TYPE,
        o_id_dep_clin_serv OUT sch_consult_vacancy.id_dep_clin_serv%TYPE,
        o_prof_name_sign   OUT VARCHAR2,
        o_prof_id          OUT professional.id_professional%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(30) := 'GET_DEFAULT_SURGEON';
        l_prof_id_wl         professional.id_professional%TYPE;
        l_prof_id_vac        professional.id_professional%TYPE;
        l_prof_name_sign_wl  VARCHAR2(4000);
        l_prof_name_sign_vac VARCHAR2(4000);
        l_id_dcs_wl          dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_dcs_vac         dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
        g_error := 'CALL GET_REQUEST_SURGEON';
        IF (get_request_surgeon(i_lang,
                                i_prof,
                                i_id_waiting_list,
                                l_prof_name_sign_wl,
                                l_prof_id_wl,
                                l_id_dcs_wl,
                                o_error))
        THEN
            o_id_dep_clin_serv := l_id_dcs_wl;
        
            IF (get_vacancy_details(i_lang,
                                    i_prof,
                                    i_id_sch_vacancy,
                                    l_id_dcs_vac,
                                    l_prof_name_sign_vac,
                                    l_prof_id_vac,
                                    o_error))
            THEN
                /*
                Na situação em que na WL não haja cirurgião indicado e haja cirurgião na sessão, 
                mas não haja match entre as especialidades do cirurgião e da WL então não devemos sugerir o 
                cirurgião da sessão.
                */
                IF (l_prof_id_wl != -1 AND l_id_dcs_vac != l_id_dcs_wl)
                THEN
                    o_prof_id        := -1;
                    o_prof_name_sign := NULL;
                ELSE
                    IF (l_prof_id_wl != -1)
                    THEN
                        o_prof_id        := l_prof_id_wl;
                        o_prof_name_sign := l_prof_name_sign_wl;
                    ELSE
                        o_prof_id        := -1;
                        o_prof_name_sign := NULL;
                    END IF;
                END IF;
            ELSE
                RETURN FALSE;
            END IF;
        
        ELSE
            RETURN FALSE;
        END IF;
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
    END get_default_surgeon;

    /**
    * returns the surgeons given the waiting list id and the vacancy id
    *
    * @param i_lang                   language id
    * @param i_prof                   Professional identification
    * @param i_id_vacancy             Vacancy id
    * @param o_surgeons               Cursor with the surgeons name
    * @para,o_default_surgeon_name    default surgeon
    * @param o_error                  error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_surgeons
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_vacancy           IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_waiting_list      IN waiting_list.id_waiting_list%TYPE,
        o_surgeons             OUT pk_types.cursor_type,
        o_default_surgeon_name OUT VARCHAR2,
        o_default_surgeon_id   OUT professional.id_professional%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(30) := 'GET_SURGEONS';
        l_id_dep_clin_serv sch_consult_vacancy.id_dep_clin_serv%TYPE;
    
    BEGIN
        g_error := 'CALL GET_DEFAULT_SURGEON';
        IF (get_default_surgeon(i_lang,
                                i_prof,
                                i_id_vacancy,
                                i_id_waiting_list,
                                l_id_dep_clin_serv,
                                o_default_surgeon_name,
                                o_default_surgeon_id,
                                o_error))
        THEN
            g_error := 'CALL get_surgeons_by_depclinserv';
            IF NOT (pk_surgery_request.get_surgeons_by_dep_clin_serv(i_lang,
                                                                     i_prof,
                                                                     NULL,
                                                                     l_id_dep_clin_serv,
                                                                     o_surgeons,
                                                                     o_error))
            THEN
                g_error := 'CALL open_my_cursor';
                pk_types.open_my_cursor(o_surgeons);
            
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL open_my_cursor';
            pk_types.open_my_cursor(o_surgeons);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_surgeons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_surgeons;

    /**
    * returns vacancy id and waiting list id associated to a schedule
    *
    * @param i_lang                language id
    * @param i_id_schedule         Schedule id
    * @param o_waiting_list_id     waiting list identification
    * @param o_vacancy_id          vacancy identification
    * @param o_error               error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_sch_details
    (
        i_lang            IN language.id_language%TYPE,
        i_id_schedule     IN schedule.id_schedule%TYPE,
        o_waiting_list_id OUT waiting_list.id_waiting_list%TYPE,
        o_vacancy_id      OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCH_DETAILS';
    BEGIN
        g_error := 'GET SCHEDULE DETAIL';
        SELECT s.id_sch_consult_vacancy, ssr.id_waiting_list
          INTO o_vacancy_id, o_waiting_list_id
          FROM schedule s
          JOIN schedule_sr ssr
            ON s.id_schedule = ssr.id_schedule
         WHERE s.id_schedule = i_id_schedule;
    
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
    END get_sch_details;

    /**
    * returns the surgeons of the dep_clin_serv to a given schedule 
    * return the default surgeon
    *
    * @param i_lang               language id
    * @param i_id_schedule        Schedule id
    * @param o_surgeons           Cursor with the surgeons name
    * @param o_default_surgeon    default surgeon 
    * @param o_default_surgeon_id default surgeon ID
    * @param o_error              error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_surgeons
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        o_surgeons             OUT pk_types.cursor_type,
        o_default_surgeon_name OUT VARCHAR2,
        o_default_surgeon_id   OUT professional.id_professional%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(30) := 'GET_SURGEONS';
        l_waiting_list_id waiting_list.id_waiting_list%TYPE;
        l_vacancy_id      sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
    BEGIN
        g_error := 'CALL GET_SCHEDULE_DETAILS';
        IF (get_sch_details(i_lang, i_id_schedule, l_waiting_list_id, l_vacancy_id, o_error))
        THEN
            g_error := 'CALL GET_SURGEONS';
            RETURN(get_surgeons(i_lang,
                                i_prof,
                                l_vacancy_id,
                                l_waiting_list_id,
                                o_surgeons,
                                o_default_surgeon_name,
                                o_default_surgeon_id,
                                o_error));
        ELSE
            pk_types.open_my_cursor(o_surgeons);
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_surgeons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_surgeons;

    /**
    * private function. check existence of given value inside a collection
    * Telmo
    */
    FUNCTION collection_exists
    (
        i_searchthis VARCHAR2,
        i_coll       table_varchar
    ) RETURN BOOLEAN IS
        i        INTEGER;
        l_exists BOOLEAN := FALSE;
        l_value  VARCHAR2(200) := nvl(i_searchthis, '-1');
    BEGIN
        IF i_coll IS NULL
        THEN
            RETURN l_exists;
        END IF;
    
        i := i_coll.first;
        WHILE i IS NOT NULL
              AND l_exists = FALSE
        LOOP
            l_exists := nvl(i_coll(i), '-1') = l_value;
            i        := i_coll.next(i);
        END LOOP;
    
        RETURN l_exists;
    END collection_exists;

    /**
    * private function. check existence of given value inside a collection.
    * overload for handling table_number
    * Telmo
    */
    FUNCTION collection_exists
    (
        i_searchthis NUMBER,
        i_coll       table_number
    ) RETURN BOOLEAN IS
        i        INTEGER;
        l_exists BOOLEAN := FALSE;
        l_value  NUMBER := nvl(i_searchthis, -99999999);
    BEGIN
        IF i_coll IS NULL
        THEN
            RETURN l_exists;
        END IF;
    
        i := i_coll.first;
        WHILE i IS NOT NULL
              AND l_exists = FALSE
        LOOP
            l_exists := nvl(i_coll(i), -99999999) = l_value;
            i        := i_coll.next(i);
        END LOOP;
    
        RETURN l_exists;
    END collection_exists;

    FUNCTION get_epis_stuff
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_wl    IN schedule_sr.id_waiting_list%TYPE,
        o_dcs_list OUT table_number,
        o_id_sch   OUT schedule.id_schedule%TYPE,
        o_id_epis  OUT episode.id_episode%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(18) := 'GET_EPIS_DCS';
        l_episodes  pk_wtl_pbl_core.t_rec_episodes;
        l_rec_dcss  pk_wtl_pbl_core.t_rec_dcss;
        i           INTEGER;
    BEGIN
    
        -- get surgery episode for this wl id
        g_error := 'CALL PK_WTL_PBL_CORE.GET_EPISODES';
        IF NOT pk_wtl_pbl_core.get_episodes(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_id_waiting_list => i_id_wl,
                                            i_id_epis_type    => pk_wtl_prv_core.g_id_epis_type_surgery,
                                            i_flg_status      => NULL,
                                            o_episodes        => l_episodes,
                                            o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- get schedule id and episode id
        g_error := 'GET ID_SCHEDULE AND ID_EPISODE';
        IF l_episodes IS NOT NULL
           AND l_episodes.exists(1)
        THEN
            o_id_sch  := l_episodes(1).id_schedule;
            o_id_epis := l_episodes(1).id_episode;
        END IF;
    
        -- sem id_episode nada feito
        IF o_id_epis IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        -- sacar dcs se nao mandaram isso
        IF NOT pk_wtl_pbl_core.get_dep_clin_servs(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_waiting_list => i_id_wl,
                                                  i_id_episode      => o_id_epis,
                                                  i_flg_type        => pk_wtl_prv_core.g_wtl_dcs_type_specialty,
                                                  i_all             => g_no,
                                                  o_dcs             => l_rec_dcss,
                                                  o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- pegar somente os id_dcs
        g_error    := 'CYCLE l_rec_dcss';
        o_dcs_list := table_number();
        i          := l_rec_dcss.first;
        WHILE i IS NOT NULL
        LOOP
            o_dcs_list.extend();
            o_dcs_list(o_dcs_list.last) := l_rec_dcss(i).id_dep_clin_serv;
            i := l_rec_dcss.next(i);
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
    END get_epis_stuff;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  general rules: see function pk_schedule.validate_schedule
    *  specific rules: see inline comments below
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is calling this
    * @param i_id_patient         Patient identification
    * @param i_dcs_list           list of dcs present in this surgery
    * @param i_id_profs_list      list of professionals participating 
    * @param i_dt_begin           requested schedule begin date. If a slot was picked, should equal its begin date
    * @param i_dt_end             requested schedule end date. If a slot was picked, should equal its end date
    * @param i_id_slot            slot id, if this request was dropped into a slot
    * @param i_id_session         vacancy id, if this request was dropped into a session (vacancy)
    * @param i_flg_urgency        Y = this is a emergency surgery N= elective surgery
    * @param i_duration           alternative to i_dt_end. only used if there is no i_dt_end. (minutes)
    * @param i_dpb                date for 'dont perform before'
    * @param i_dpa                date for 'dont perform after'
    * @param i_pref_dt_begin      preferred begin date included in the request
    * @param i_pref_dt_end        preferred end date included in the request
    * @param i_dt_surgery         recommended date for surgery
    * @param i_id_wl              waiting list id
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Telmo
    * @version  2.5
    * @date     06-04-2009
    */
    FUNCTION validate_schedule_internal
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN sch_group.id_patient%TYPE,
        i_dcs_list      IN table_number,
        i_id_profs_list IN table_number,
        i_dt_begin      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        i_id_slot       IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        i_id_session    IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        i_flg_urgency   IN VARCHAR2 DEFAULT NULL,
        i_duration      IN NUMBER DEFAULT NULL,
        i_dpb           IN VARCHAR2 DEFAULT NULL,
        i_dpa           IN VARCHAR2 DEFAULT NULL,
        i_pref_dt_begin IN VARCHAR2 DEFAULT NULL,
        i_pref_dt_end   IN VARCHAR2 DEFAULT NULL,
        i_dt_surgery    IN VARCHAR2 DEFAULT NULL,
        i_id_wl         IN schedule_sr.id_waiting_list%TYPE,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(18) := 'VALIDATE_SCHEDULE';
        i                NUMBER;
        l_stoperror      BOOLEAN := FALSE;
        l_msg_stack      pk_schedule.t_msg_stack;
        l_dt_begin       TIMESTAMP WITH TIME ZONE;
        l_dt_end         TIMESTAMP WITH TIME ZONE;
        l_dt_begin_trunc TIMESTAMP WITH TIME ZONE;
        l_dt_end_trunc   TIMESTAMP WITH TIME ZONE;
        l_pref_dt_begin  TIMESTAMP WITH TIME ZONE;
        l_pref_dt_end    TIMESTAMP WITH TIME ZONE;
        l_dpb            TIMESTAMP WITH TIME ZONE;
        l_dpb_trunc      TIMESTAMP WITH TIME ZONE;
        l_dpa            TIMESTAMP WITH TIME ZONE;
        l_dpa_trunc      TIMESTAMP WITH TIME ZONE;
        l_dt_surgery     TIMESTAMP WITH TIME ZONE;
        l_id_prof        NUMBER;
        no_data EXCEPTION;
        l_unavs     VARCHAR2(4000);
        l_message   VARCHAR2(2000);
        l_pat_unavs pk_wtl_pbl_core.t_rec_unavailabilities;
        l_id_dcs    NUMBER;
    
        CURSOR c_slot_data
        (
            in_dt_begin TIMESTAMP WITH TIME ZONE,
            in_dt_end   TIMESTAMP WITH TIME ZONE
        ) IS
            SELECT scv.id_institution,
                   scv.id_prof,
                   scv.id_dep_clin_serv,
                   scv.id_room,
                   scv.id_sch_event,
                   scv.dt_begin_tstz,
                   scv.dt_end_tstz,
                   scvo.flg_urgency,
                   scvos.dt_begin,
                   scvos.dt_end
              FROM sch_consult_vacancy scv
              JOIN sch_consult_vac_oris scvo
                ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
              JOIN sch_consult_vac_oris_slot scvos
                ON scvo.id_sch_consult_vacancy = scvos.id_sch_consult_vacancy
             WHERE scvos.id_sch_consult_vac_oris_slot = i_id_slot
               AND in_dt_begin BETWEEN scvos.dt_begin AND scvos.dt_end
               AND in_dt_end BETWEEN scvos.dt_begin AND scvos.dt_end;
        r_slot_data c_slot_data%ROWTYPE;
    
        CURSOR c_slot_data2
        (
            in_dt_begin TIMESTAMP WITH TIME ZONE,
            in_dt_end   TIMESTAMP WITH TIME ZONE
        ) IS
            SELECT scv.id_institution,
                   scv.id_prof,
                   scv.id_dep_clin_serv,
                   scv.id_room,
                   scv.id_sch_event,
                   scv.dt_begin_tstz,
                   scv.dt_end_tstz,
                   scvo.flg_urgency,
                   scvos.dt_begin,
                   scvos.dt_end
              FROM sch_consult_vacancy scv
              JOIN sch_consult_vac_oris scvo
                ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
              JOIN sch_consult_vac_oris_slot scvos
                ON scvo.id_sch_consult_vacancy = scvos.id_sch_consult_vacancy
             WHERE scvos.id_sch_consult_vac_oris_slot =
                   (SELECT id_sch_consult_vac_oris_slot
                      FROM sch_consult_vac_oris_slot s
                     WHERE s.id_sch_consult_vacancy = i_id_session
                       AND s.dt_begin = (SELECT MIN(dt_begin)
                                           FROM sch_consult_vac_oris_slot sl
                                          WHERE sl.id_sch_consult_vacancy = i_id_session
                                            AND in_dt_begin BETWEEN sl.dt_begin AND sl.dt_end
                                            AND in_dt_end BETWEEN sl.dt_begin AND sl.dt_end)
                       AND rownum = 1);
    
        CURSOR c_unav_profs
        (
            in_dt_begin TIMESTAMP WITH TIME ZONE,
            in_dt_end   TIMESTAMP WITH TIME ZONE
        ) IS
            SELECT sa.id_professional, pk_prof_utils.get_name_signature(i_lang, i_prof, sa.id_professional) nombre
              FROM sch_absence sa
             WHERE sa.id_professional IN (SELECT column_value
                                            FROM TABLE(i_id_profs_list))
               AND sa.id_institution = i_prof.institution
               AND sa.flg_status = g_active
               AND (in_dt_begin BETWEEN sa.dt_begin_tstz AND sa.dt_end_tstz OR
                   in_dt_end BETWEEN sa.dt_begin_tstz AND sa.dt_end_tstz);
        rec c_unav_profs%ROWTYPE;
    
    BEGIN
        o_flg_proceed := g_yes;
        o_flg_show    := g_no;
    
        -- pick foist prof
        SELECT nvl2(i_id_profs_list, i_id_profs_list(1), NULL)
          INTO l_id_prof
          FROM dual;
        -- convert requested schedule start to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR i_dt_begin';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- if i_dt_end is not present, try to calculate it using i_duration
        g_error := 'CALCULATE l_dt_end with i_duration';
        IF i_dt_end IS NULL
           AND i_duration IS NOT NULL
        THEN
            l_dt_end := pk_date_utils.add_to_ltstz(l_dt_begin, i_duration, 'MINUTE');
        ELSE
            g_error := 'CALL GET_STRING_TSTZ FOR i_dt_end';
            -- convert requested schedule end to timestamp
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_end,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_end,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        -- set the dcs straight
        IF i_dcs_list IS NOT NULL
           AND i_dcs_list.exists(1)
           AND i_dcs_list(1) IS NOT NULL
        THEN
            l_id_dcs := i_dcs_list(1);
        END IF;
    
        -- RULE 1: existence of a proper slot is mandatory. 
        -- Also this is where we fetch slot data
        IF i_id_slot IS NULL
           AND i_id_session IS NULL
        THEN
            RAISE no_data;
        ELSIF i_id_slot IS NOT NULL
        THEN
            OPEN c_slot_data(l_dt_begin, l_dt_end);
            FETCH c_slot_data
                INTO r_slot_data;
            IF NOT c_slot_data%FOUND
            THEN
                pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_no_proper_slot), g_stop_error); --blocker message
            END IF;
            CLOSE c_slot_data;
        ELSIF i_id_session IS NOT NULL
        THEN
            OPEN c_slot_data2(l_dt_begin, l_dt_end);
            FETCH c_slot_data2
                INTO r_slot_data;
            IF NOT c_slot_data2%FOUND
            THEN
                -- get sys_message 
                g_error := 'RULE 1';
                IF NOT pk_schedule.get_validation_msgs(i_lang         => i_lang,
                                                       i_code_msg     => g_msg_no_proper_vacancy,
                                                       i_pkg_name     => g_package_name,
                                                       i_replacements => table_varchar(pk_schedule.string_date_hm(i_lang,
                                                                                                                  i_prof,
                                                                                                                  l_dt_begin),
                                                                                       pk_schedule.string_date_hm(i_lang,
                                                                                                                  i_prof,
                                                                                                                  l_dt_end)),
                                                       o_message      => l_message,
                                                       o_error        => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                pk_schedule.message_push(l_message, g_stop_error); --blocker message
            END IF;
            CLOSE c_slot_data2;
        END IF;
    
        -- RULE 2: the slot's dcs should equal at least one of the request's dcs
        IF i_dcs_list IS NULL
           OR (i_dcs_list.exists(1) AND i_dcs_list(1) IS NULL)
           OR NOT collection_exists(r_slot_data.id_dep_clin_serv, i_dcs_list)
        THEN
            pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_no_dcs_present), 1);
        END IF;
    
        -- RULE 3: urgencia recebida nao coincide com atributo de urgencia da sessao
        IF nvl(i_flg_urgency, g_no) <> r_slot_data.flg_urgency
        THEN
            pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_dif_urgency_level), 1);
        END IF;
    
        -- RULE 4: prof. da sessao (se houver) deve ser igual ao prof. da cirurgia
        IF r_slot_data.id_prof IS NOT NULL
           AND NOT collection_exists(r_slot_data.id_prof, i_id_profs_list)
        THEN
            pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_no_prof_present), 1);
        END IF;
    
        -- RULE 5: verificar se ha indisponibilidade de algum profissional
        IF i_id_profs_list IS NOT NULL
        THEN
            -- obter lista dos indisponiveis
            OPEN c_unav_profs(l_dt_begin, l_dt_end);
            LOOP
                FETCH c_unav_profs
                    INTO rec;
                EXIT WHEN c_unav_profs%NOTFOUND;
                l_unavs := nvl(l_unavs, ' ') || CASE
                               WHEN length(l_unavs) > 0 THEN
                                ', '
                               ELSE
                                ''
                           END || rec.nombre;
            END LOOP;
            CLOSE c_unav_profs;
            -- se ha indisponiveis criar a mensagem
            IF length(l_unavs) > 0
            THEN
                -- get sys_message 
                g_error := 'RULE 5';
                IF NOT pk_schedule.get_validation_msgs(i_lang         => i_lang,
                                                       i_code_msg     => g_msg_prof_unav,
                                                       i_pkg_name     => g_package_name,
                                                       i_replacements => table_varchar(l_unavs),
                                                       o_message      => l_message,
                                                       o_error        => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                pk_schedule.message_push(l_message, 1);
            END IF;
        END IF;
    
        -- RULE 6: comparacao com o periodo preferido na requisicao
        IF i_pref_dt_begin IS NOT NULL
        THEN
            -- convert requested schedule start to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR i_pref_dt_begin';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_pref_dt_begin,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_pref_dt_begin,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- compare with l_dt_begin
            IF l_dt_begin < l_pref_dt_begin
            THEN
                pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_pref_dt_begin), 1);
            END IF;
        END IF;
    
        IF i_pref_dt_end IS NOT NULL
        THEN
            -- convert requested schedule start to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR i_pref_dt_end';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_pref_dt_end,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_pref_dt_end,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- compare with l_dt_end
            IF l_dt_end > l_pref_dt_end
            THEN
                pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_pref_dt_end), 1);
            END IF;
        END IF;
    
        -- RULE 7: validacao da dpb(dont perform before) e dpa(dont perform after)
        IF i_dpb IS NOT NULL
        THEN
            g_error := 'CALL GET_STRING_TSTZ FOR i_dpb';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dpb,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dpb,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_dpb_trunc      := pk_date_utils.trunc_insttimezone(i_prof, l_dpb);
            l_dt_begin_trunc := pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin);
        
            -- compare with l_dt_begin
            IF l_dt_begin_trunc < l_dpb_trunc
            THEN
                pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_dpb), 1);
            END IF;
        END IF;
    
        IF i_dpa IS NOT NULL
        THEN
            -- convert requested schedule start to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR i_dpa';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dpa,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dpa,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_dpa_trunc    := pk_date_utils.trunc_insttimezone(i_prof, l_dpa);
            l_dt_end_trunc := pk_date_utils.trunc_insttimezone(i_prof, l_dt_end);
            -- compare with l_dt_end
            IF l_dt_end_trunc > l_dpa_trunc
            THEN
                pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_dpa), 1);
            END IF;
        END IF;
    
        -- RULE 8: nao pode haver sobreposicao de agendamentos nesta sala
        DECLARE
            l_patname patient.name%TYPE;
            l_dt_beg  VARCHAR2(40);
            l_dt_en   VARCHAR2(40);
        BEGIN
            SELECT pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, s.id_episode) name,
                   pk_schedule.string_date_hm(i_lang, i_prof, s.dt_begin_tstz),
                   pk_schedule.string_date_hm(i_lang, i_prof, s.dt_end_tstz)
              INTO l_patname, l_dt_beg, l_dt_en
              FROM schedule s
              JOIN schedule_sr sr
                ON s.id_schedule = sr.id_schedule
              JOIN sch_group sg
                ON sr.id_schedule = sg.id_schedule
              JOIN patient pat
                ON sg.id_patient = pat.id_patient
             WHERE s.flg_sch_type = g_surgery_dep_type
               AND s.flg_status <> pk_schedule.g_status_canceled
               AND ((l_dt_begin >= s.dt_begin_tstz AND l_dt_begin < s.dt_end_tstz) OR
                   (l_dt_end > s.dt_begin_tstz AND l_dt_end <= s.dt_end_tstz))
               AND s.id_room = r_slot_data.id_room
               AND rownum = 1;
        
            -- chegando aqui e porque encontrou sobreposicao
            g_error := 'RULE 8';
            IF NOT pk_schedule.get_validation_msgs(i_lang         => i_lang,
                                                   i_code_msg     => g_msg_sched_overlap,
                                                   i_pkg_name     => g_package_name,
                                                   i_replacements => table_varchar(l_patname, l_dt_beg, l_dt_en),
                                                   o_message      => l_message,
                                                   o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            pk_schedule.message_push(l_message, g_stop_error);
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- RULE 9: validacao dos periodos de indisponibilidade do paciente
        IF i_id_wl IS NOT NULL
        THEN
            -- fetch unav periods
            IF NOT pk_wtl_pbl_core.get_unavailability(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_id_waiting_list  => i_id_wl,
                                                      o_unavailabilities => l_pat_unavs,
                                                      o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            i := l_pat_unavs.first;
            WHILE i IS NOT NULL
            LOOP
                IF (l_pat_unavs(i)
                   .dt_unav_start IS NOT NULL AND l_pat_unavs(i).dt_unav_start BETWEEN l_dt_begin AND l_dt_end)
                   OR (l_pat_unavs(i)
                   .dt_unav_end IS NOT NULL AND l_pat_unavs(i).dt_unav_end BETWEEN l_dt_begin AND l_dt_end)
                THEN
                    g_error := 'RULE 9';
                    IF NOT pk_schedule.get_validation_msgs(i_lang         => i_lang,
                                                           i_code_msg     => g_msg_pat_unav,
                                                           i_pkg_name     => g_package_name,
                                                           i_replacements => table_varchar(pk_schedule.string_date_hm(i_lang,
                                                                                                                      i_prof,
                                                                                                                      l_pat_unavs(i)
                                                                                                                      .dt_unav_start),
                                                                                           pk_schedule.string_date_hm(i_lang,
                                                                                                                      i_prof,
                                                                                                                      l_pat_unavs(i)
                                                                                                                      .dt_unav_end)),
                                                           o_message      => l_message,
                                                           o_error        => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    pk_schedule.message_push(l_message, 1);
                END IF;
            
                i := l_pat_unavs.next(i);
            END LOOP;
        
        END IF;
    
        -- RULE 10: validacao da data recomendada de agendamento
        IF i_dt_surgery IS NOT NULL
        THEN
            g_error := 'CALL GET_STRING_TSTZ FOR i_dt_surgery';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_surgery,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_surgery,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
            -- compare with l_dt_begin and l_dt_end
            IF l_dt_surgery NOT BETWEEN trunc(l_dt_begin) AND trunc(l_dt_end) + 1
            THEN
                pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_rec_surg_date), 1);
            END IF;
        END IF;
    
        -- THE OTHER USUAL RULES
        g_error := 'CALL PK_SCHEDULE.VALIDATE_SCHEDULE';
        IF NOT pk_schedule.validate_schedule(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_patient       => i_id_patient,
                                             i_id_sch_event     => r_slot_data.id_sch_event,
                                             i_id_dep_clin_serv => l_id_dcs, --i_dcs_list(1),
                                             i_id_prof          => l_id_prof,
                                             i_dt_begin         => i_dt_begin,
                                             o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        ------- CREATE RETURN MESSAGE ------------------------------------------------------------------------
        g_error := 'Processing return message';
    
        IF pk_schedule.g_msg_stack.count > 1
        THEN
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            /*o_button    := pk_schedule.g_cancel_button_code ||
            pk_message.get_message(i_lang, pk_schedule.g_cancel_button) || '|';*/
            pk_schedule.message_flush(o_msg);
        
            -- a presenca da g_begindatelower ou duma g_stop_error na stack impede a mostragem do botao de prosseguir 
            i := pk_schedule.g_msg_stack.first;
            WHILE i IS NOT NULL
                  AND l_stoperror = FALSE
            LOOP
                l_msg_stack := pk_schedule.g_msg_stack(i);
                --                o_msg       := l_msg_stack.msg;
                l_stoperror := l_msg_stack.idxmsg = pk_schedule.g_begindatelower OR l_msg_stack.idxmsg = g_stop_error;
                i           := pk_schedule.g_msg_stack.next(i);
            END LOOP;
        
            -- acrescenta o botao de prosseguir se essa mensagem nao esta' na stack
            IF NOT nvl(l_stoperror, FALSE)
            THEN
                --                pk_schedule.message_flush(o_msg);
                o_button := pk_schedule.g_cancel_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_cancel_button) || '|' ||
                            pk_schedule.g_ok_button_code ||
                            pk_message.get_message(i_lang, pk_schedule.g_sched_msg_ignore_proceed) || '|';
            ELSE
                o_button := pk_schedule.g_r_button_code || pk_message.get_message(i_lang, pk_schedule.g_sched_msg_read) || '|';
            END IF;
            o_flg_show    := g_yes;
            o_flg_proceed := g_yes;
        END IF;
    
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
    END validate_schedule_internal;

    /**
    * Wrapper for validate_schedule to be used for validating schedules coming from the WL.
    * Flash layer should use this one.
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is calling this
    * @param i_dcs_list           list of dcs present in this surgery
    * @param i_id_profs_list      list of professionals participating 
    * @param i_dt_begin           requested schedule begin date. If a slot was picked, should equal its begin date
    * @param i_dt_end             requested schedule end date. If a slot was picked, should equal its end date
    * @param i_id_wl              id do registo na WL que se dragou
    * @param i_id_slot            slot id, if this request was dropped into a slot
    * @param i_id_session         vacancy id, if this request was dropped into a session (vacancy)
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Telmo
    * @version  2.5
    * @date     06-04-2009
    */
    FUNCTION validate_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dcs_list      IN table_number,
        i_id_profs_list IN table_number,
        i_dt_begin      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        i_id_wl         IN schedule_sr.id_waiting_list%TYPE,
        i_id_slot       IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        i_id_session    IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(18) := 'VALIDATE_SCHEDULE';
        l_id_patient  schedule_sr.id_patient%TYPE;
        l_flg_urgency VARCHAR2(1);
        l_duration    NUMBER;
        l_dpb         waiting_list.dt_dpb%TYPE;
        l_dpa         waiting_list.dt_dpa%TYPE;
        --        l_pref_dt_begin   VARCHAR2(20);
        --        l_pref_dt_end     VARCHAR2(20);
        l_flg_type            waiting_list.flg_type%TYPE;
        l_flg_status          waiting_list.flg_status%TYPE;
        l_dt_surgery          waiting_list.dt_surgery%TYPE;
        l_min_inform_time     waiting_list.min_inform_time%TYPE;
        l_id_urg_level        waiting_list.id_wtl_urg_level%TYPE;
        l_dcs_list            table_number := i_dcs_list;
        l_id_schedule         schedule.id_schedule%TYPE;
        l_id_episode          schedule.id_episode%TYPE;
        l_id_expernal_request waiting_list.id_external_request%TYPE;
    BEGIN
        -- fetch WL data
        g_error := 'CALL PK_WTL_PBL_CORE.GET_DATA';
    
        IF NOT pk_wtl_pbl_core.get_data(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_waiting_list     => i_id_wl,
                                        o_id_patient          => l_id_patient,
                                        o_flg_type            => l_flg_type,
                                        o_flg_status          => l_flg_status,
                                        o_dpb                 => l_dpb,
                                        o_dpa                 => l_dpa,
                                        o_dt_surgery          => l_dt_surgery,
                                        o_min_inform_time     => l_min_inform_time,
                                        o_id_urgency_lev      => l_id_urg_level,
                                        o_id_external_request => l_id_expernal_request,
                                        o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- obter dcs se nao enviaram.
        IF i_dcs_list IS NULL
           OR NOT i_dcs_list.exists(1)
           OR i_dcs_list(1) IS NULL
        THEN
            g_error := 'CALL GET_EPIS_STUFF';
            IF NOT get_epis_stuff(i_lang     => i_lang,
                                  i_prof     => i_prof,
                                  i_id_wl    => i_id_wl,
                                  o_dcs_list => l_dcs_list,
                                  o_id_sch   => l_id_schedule,
                                  o_id_epis  => l_id_episode,
                                  o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            l_dcs_list := i_dcs_list;
        END IF;
    
        -- a lista de dcs que vem de fora ainda tem prioridade
        /*        IF i_dcs_list IS NOT NULL
                   AND i_dcs_list.EXISTS(1)
                   AND TRIM(i_dcs_list(1)) IS NOT NULL
                THEN
                    l_dcs_list := i_dcs_list;
                END IF;
        */
        -- call the working validate
        g_error := 'CALL VALIDATE_SCHEDULE(2)';
        IF NOT validate_schedule_internal(i_lang => i_lang,
                                          
                                          i_prof          => i_prof,
                                          i_id_patient    => l_id_patient,
                                          i_dcs_list      => l_dcs_list,
                                          i_id_profs_list => i_id_profs_list,
                                          i_dt_begin      => i_dt_begin,
                                          i_dt_end        => i_dt_end,
                                          i_id_slot       => i_id_slot,
                                          i_id_session    => i_id_session,
                                          i_flg_urgency   => l_flg_urgency,
                                          i_duration      => l_duration,
                                          i_dpb           => pk_date_utils.date_send_tsz(i_lang, l_dpb, i_prof),
                                          i_dpa           => pk_date_utils.date_send_tsz(i_lang, l_dpa, i_prof),
                                          i_pref_dt_begin => NULL, --l_pref_dt_begin,
                                          i_pref_dt_end   => NULL, --l_pref_dt_end,
                                          i_dt_surgery    => pk_date_utils.date_send_tsz(i_lang, l_dt_surgery, i_prof),
                                          i_id_wl         => i_id_wl,
                                          o_flg_proceed   => o_flg_proceed,
                                          o_flg_show      => o_flg_show,
                                          o_msg           => o_msg,
                                          o_msg_title     => o_msg_title,
                                          o_button        => o_button,
                                          o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
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
    END validate_schedule;

    /**
    * Gets a set of ORIS schedules.
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_department                Department ID
    * @param i_id_room                      Room ID
    * @param i_id_dcs                       Dep_clin_serv ID
    * @param i_id_prof                      Professional ID
    * @param i_start_date                   Begin date
    * @param i_end_date                     End date
    * @param i_flg_wizard                   Type of wizard (CA - Cancel, CO - Confirm)
    * @param o_schedules                    Schedules 
    * @param o_error                        Error message if something goes wrong
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    */
    FUNCTION get_related_schedules
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN table_number,
        i_id_room       IN table_number,
        i_id_dcs        IN table_number,
        i_id_prof       IN table_number,
        i_start_date    IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        i_flg_wizard    IN VARCHAR2,
        o_schedules     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_RELATED_SCHEDULES';
        l_dt_begin  TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end    TIMESTAMP WITH LOCAL TIME ZONE;
        l_room_ids  table_number;
    
    BEGIN
    
        g_error    := 'CALL GET_UNION_ROOMS FUNCTION';
        l_room_ids := get_union_rooms(i_lang => i_lang, i_dept_ids => i_id_department, i_room_ids => i_id_room);
    
        g_error := 'CALL PK_DATE_UTILS.GET_STRING_TSTZ';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_start_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
        g_error := 'CALL 2 PK_DATE_UTILS.GET_STRING_TSTZ';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_end_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_schedules';
        OPEN o_schedules FOR
            SELECT s.id_schedule,
                   --                   get_month_abrev(i_lang, to_char(s.dt_begin_tstz, 'MM'))
                   get_month_abrev(i_lang,
                                   pk_date_utils.date_month_tsz(i_lang,
                                                                s.dt_begin_tstz,
                                                                i_prof.institution,
                                                                i_prof.software)) || ' ' ||
                   pk_date_utils.date_dayyear_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) begin_date, --to_char(s.dt_begin_tstz, 'DD YYYY') begin_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) begin_hour, --to_char(s.dt_begin_tstz, 'HH24:MI') || 'h' begin_hour,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_end_tstz, i_prof.institution, i_prof.software) end_hour, --to_char(s.dt_end_tstz, 'HH24:MI') || 'h' end_hour,
                   
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, s.id_episode) pat_name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   sg.id_patient,
                   s.id_dcs_requested,
                   pk_schedule.string_dep_clin_serv(i_lang, s.id_dcs_requested) desc_dcs,
                   pk_wtl_pbl_core.get_surg_proc_string(i_lang, i_prof, ss.id_waiting_list) desc_surgery,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_professional) prof_name,
                   get_dep_name_from_room(i_lang, r.id_room) dep_desc,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_desc
              FROM schedule s, sch_consult_vacancy scv, room r, sch_group sg, sch_resource sr, schedule_sr ss
             WHERE s.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
               AND scv.id_room = r.id_room
               AND s.id_schedule = sg.id_schedule
               AND s.id_schedule = sr.id_schedule
               AND s.id_schedule = ss.id_schedule
               AND s.id_sch_event = g_surg_sch_event
               AND s.flg_status != g_canceled
                  -- exclude the registered episodes
               AND pk_sr_visit.is_epis_registered(i_lang, s.id_episode) = pk_alert_constant.g_no
                  --
               AND ss.flg_temporary = CASE
                       WHEN i_flg_wizard = 'CO' THEN
                        g_yes
                       ELSE
                        ss.flg_temporary
                   END
               AND s.id_room IN (SELECT *
                                   FROM TABLE(l_room_ids))
               AND s.id_dcs_requested IN (SELECT *
                                            FROM TABLE(i_id_dcs))
               AND sr.id_professional IN (SELECT *
                                            FROM TABLE(i_id_prof))
               AND s.dt_begin_tstz >= l_dt_begin
               AND (l_dt_end IS NULL OR (s.dt_end_tstz <= l_dt_end AND l_dt_end IS NOT NULL))
             ORDER BY s.dt_begin_tstz;
    
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
            -- If function called by FLASH                                              
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_related_schedules;

    /*
            * Create oris schedule.
            *
            * @param i_lang               Language
            * @param i_prof               Professional who is doing the scheduling
            * @param i_id_schedule        se vier preenchido e' para actualizar
            * @param i_id_patient         Patient id
            * @param i_dcs_list           list of dcs present in this surgery
            * @param i_id_profs_list      list of professionals participating 
            * @param i_dt_begin           Schedule begin date
            * @param i_dt_end             Schedule end date
            * @param i_flg_tempor         Y=temporary N=definitive
            * @param i_flg_vacancy        Vacancy flag
            * @param i_id_room            Room
            * @param i_id_schedule_ref    old schedule id. Used if this function is called by update_schedule
            * @param i_id_episode         surgery Episode id
    --        * @param _id_epis_status      status of surgery episode
            * @param i_id_slot            slot id, if this request was dropped into a slot
            * @param i_id_session         vacancy id, if this request was dropped into a session (vacancy)
            * @param i_id_wl              waiting list needed here only to be referenced in schedule_sr
            * @param i_icu                Need of Intensive Care Unit. sr specific data
            * @param i_pos                pre operative screening value. sr specific data
            * @param i_notes              wl notes. sr specific data
            * @param o_id_schedule        Newly generated schedule id 
            * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
            * @param o_flg_show           Set if a message is displayed or not      
            * @param o_msg                Message body to be displayed in flash
            * @param o_msg_title          Message title
            * @param o_button             Buttons to show.
            * @param o_error              Error message if something goes wrong
            *
            * @author   Telmo Castro
            * @version  2.5
            * @date     09-04-2009
        */
    FUNCTION create_schedule_internal
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_dcs_list            IN table_number,
        i_id_profs_list       IN table_number,
        i_dt_begin            IN VARCHAR2,
        i_dt_end              IN VARCHAR2,
        i_flg_tempor          IN schedule_sr.flg_temporary%TYPE DEFAULT 'Y',
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE DEFAULT 'R', -- a flg_urgency vem para aqui
        i_id_room             IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_schedule_ref     IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_episode          IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_slot             IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE,
        i_id_session          IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        i_id_wl               IN NUMBER,
        i_icu                 IN schedule_sr.icu%TYPE DEFAULT NULL,
        i_notes               IN schedule_sr.notes%TYPE DEFAULT NULL,
        i_id_external_request IN waiting_list.id_external_request%TYPE,
        o_id_schedule         OUT schedule.id_schedule%TYPE,
        o_flg_proceed         OUT VARCHAR2,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'CREATE_SCHEDULE';
        l_id_sch_event sch_event.id_sch_event%TYPE;
        l_dt_begin     TIMESTAMP WITH TIME ZONE;
        l_dt_end       TIMESTAMP WITH TIME ZONE;
        l_hasperm      VARCHAR2(10);
        l_dep_type     sch_dep_type.dep_type%TYPE;
        l_no_vacancy    EXCEPTION;
        l_no_permission EXCEPTION;
        l_no_vac_usage  EXCEPTION;
        l_dummy                sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        o_id_schedule_sr       schedule_sr.id_schedule_sr%TYPE;
        o_r_schedule           schedule%ROWTYPE;
        o_r_sch_group          sch_group%ROWTYPE;
        o_r_sch_resource       sch_resource%ROWTYPE;
        l_id_dept              department.id_department%TYPE;
        l_vacancy_usage        BOOLEAN;
        l_sched_w_vac          BOOLEAN;
        l_edit_vac             BOOLEAN;
        l_occupied             sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_id_sch_sr            schedule_sr.id_schedule_sr%TYPE;
        l_id_schedule          schedule.id_schedule%TYPE;
        l_notification_default sch_dcs_notification.notification_default%TYPE;
        l_flg_status           schedule.flg_status%TYPE;
        l_id_sch               schedule.id_schedule%TYPE;
        l_id_schedule_ref      schedule.id_schedule_ref%TYPE;
        -- slot and session validated data
        l_s_dt_begin   sch_consult_vac_oris_slot.dt_begin%TYPE;
        l_s_dt_end     sch_consult_vac_oris_slot.dt_end%TYPE;
        l_s_id_room    sch_consult_vacancy.id_room%TYPE := i_id_room;
        l_s_id_eve     sch_consult_vacancy.id_sch_event%TYPE;
        l_s_id_inst    sch_consult_vacancy.id_institution%TYPE := i_prof.institution;
        l_s_id_prof    sch_consult_vacancy.id_prof%TYPE := i_id_profs_list(1);
        l_s_id_dcs     sch_consult_vacancy.id_dep_clin_serv%TYPE := i_dcs_list(1);
        l_s_id_slot    sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE := i_id_slot;
        l_s_id_session sch_consult_vac_oris_slot.id_sch_consult_vacancy%TYPE := i_id_session;
    
        -- validate and get slot data. first try is by slot id. Second try is by session id. 
        -- Third and last try is by everything else available.
        FUNCTION inner_get_slot_data
        (
            i_lang        IN language.id_language%TYPE,
            i_prof        IN profissional,
            i_dt_begin    IN sch_consult_vac_oris_slot.dt_begin%TYPE,
            i_dt_end      IN sch_consult_vac_oris_slot.dt_end%TYPE,
            io_dt_begin   IN OUT sch_consult_vac_oris_slot.dt_begin%TYPE,
            io_dt_end     IN OUT sch_consult_vac_oris_slot.dt_end%TYPE,
            io_id_room    IN OUT sch_consult_vacancy.id_room%TYPE,
            io_id_eve     IN OUT sch_consult_vacancy.id_sch_event%TYPE,
            io_id_inst    IN OUT sch_consult_vacancy.id_institution%TYPE,
            io_id_prof    IN OUT sch_consult_vacancy.id_prof%TYPE,
            io_id_dcs     IN OUT sch_consult_vacancy.id_dep_clin_serv%TYPE,
            io_id_slot    IN OUT sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
            io_id_session IN OUT sch_consult_vac_oris.id_sch_consult_vacancy%TYPE,
            o_error       OUT t_error_out
        ) RETURN BOOLEAN IS
            l_func_name VARCHAR2(32) := 'INNER_GET_SLOT_DATA';
        BEGIN
            g_error := 'SEARCH BY SLOT ID';
            IF io_id_slot IS NOT NULL
            THEN
                BEGIN
                    SELECT scv.id_sch_consult_vacancy,
                           scv.id_institution,
                           scv.id_prof,
                           scv.id_dep_clin_serv,
                           scv.id_room,
                           scv.id_sch_event,
                           scvos.id_sch_consult_vac_oris_slot,
                           scvos.dt_begin,
                           scvos.dt_end
                      INTO io_id_session,
                           io_id_inst,
                           io_id_prof,
                           io_id_dcs,
                           io_id_room,
                           io_id_eve,
                           io_id_slot,
                           io_dt_begin,
                           io_dt_end
                      FROM sch_consult_vacancy scv
                      JOIN sch_consult_vac_oris scvo
                        ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
                      JOIN sch_consult_vac_oris_slot scvos
                        ON scvo.id_sch_consult_vacancy = scvos.id_sch_consult_vacancy
                     WHERE scvos.id_sch_consult_vac_oris_slot = io_id_slot
                       AND i_dt_begin BETWEEN scvos.dt_begin AND scvos.dt_end
                       AND i_dt_end BETWEEN scvos.dt_begin AND scvos.dt_end
                       AND scv.flg_status = pk_schedule_bo.g_status_active;
                EXCEPTION
                    WHEN no_data_found THEN
                        io_id_slot := NULL;
                END;
            END IF;
        
            -- nao encontrou por slot id ou nao foi fornecida slot id - vai tentar por session id
            g_error := 'SEARCH BY SESSION ID';
            IF io_id_slot IS NULL
               AND io_id_session IS NOT NULL
            THEN
                BEGIN
                    SELECT scv.id_sch_consult_vacancy,
                           scv.id_institution,
                           scv.id_prof,
                           scv.id_dep_clin_serv,
                           scv.id_room,
                           scv.id_sch_event,
                           scvos.id_sch_consult_vac_oris_slot,
                           scvos.dt_begin,
                           scvos.dt_end
                      INTO io_id_session,
                           io_id_inst,
                           io_id_prof,
                           io_id_dcs,
                           io_id_room,
                           io_id_eve,
                           io_id_slot,
                           io_dt_begin,
                           io_dt_end
                      FROM sch_consult_vacancy scv
                      JOIN sch_consult_vac_oris scvo
                        ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
                      JOIN sch_consult_vac_oris_slot scvos
                        ON scvo.id_sch_consult_vacancy = scvos.id_sch_consult_vacancy
                     WHERE scvos.id_sch_consult_vac_oris_slot =
                           (SELECT id_sch_consult_vac_oris_slot
                              FROM sch_consult_vac_oris_slot s
                             WHERE s.id_sch_consult_vacancy = i_id_session
                               AND s.dt_begin = (SELECT MIN(dt_begin)
                                                   FROM sch_consult_vac_oris_slot sl
                                                  WHERE sl.id_sch_consult_vacancy = io_id_session
                                                    AND i_dt_begin BETWEEN sl.dt_begin AND sl.dt_end
                                                    AND i_dt_end BETWEEN sl.dt_begin AND sl.dt_end)
                               AND rownum = 1)
                       AND scv.flg_status = pk_schedule_bo.g_status_active;
                EXCEPTION
                    WHEN no_data_found THEN
                        io_id_slot    := NULL;
                        io_id_session := NULL;
                END;
            END IF;
        
            -- terceira tentativa. vai por todos os atributos. O update_schedule entra aqui
            IF io_id_slot IS NULL
               AND io_id_session IS NULL
            THEN
                BEGIN
                    SELECT scv.id_sch_consult_vacancy,
                           scv.id_institution,
                           scv.id_prof,
                           scv.id_dep_clin_serv,
                           scv.id_room,
                           scv.id_sch_event,
                           scvos.id_sch_consult_vac_oris_slot,
                           scvos.dt_begin,
                           scvos.dt_end
                      INTO io_id_session,
                           io_id_inst,
                           io_id_prof,
                           io_id_dcs,
                           io_id_room,
                           io_id_eve,
                           io_id_slot,
                           io_dt_begin,
                           io_dt_end
                      FROM sch_event e
                      JOIN sch_consult_vacancy scv
                        ON e.id_sch_event = scv.id_sch_event
                      JOIN sch_consult_vac_oris scvo
                        ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
                      JOIN sch_consult_vac_oris_slot scvos
                        ON scvo.id_sch_consult_vacancy = scvos.id_sch_consult_vacancy
                     WHERE e.dep_type = g_surgery_dep_type
                       AND scv.id_institution = io_id_inst
                       AND (io_id_room IS NULL OR nvl(scv.id_room, io_id_room) = io_id_room)
                       AND (io_id_prof IS NULL OR nvl(scv.id_prof, io_id_prof) = io_id_prof)
                       AND (io_id_dcs IS NULL OR nvl(scv.id_dep_clin_serv, io_id_dcs) = io_id_dcs)
                       AND i_dt_begin BETWEEN scvos.dt_begin AND scvos.dt_end
                       AND i_dt_end BETWEEN scvos.dt_begin AND scvos.dt_end
                       AND scv.flg_status = pk_schedule_bo.g_status_active
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
                -- ultima tentativa (desesperada). vai apenas pelos atributos obrigatorios
                IF io_id_session IS NULL
                THEN
                    BEGIN
                        SELECT scv.id_sch_consult_vacancy,
                               scv.id_institution,
                               scv.id_prof,
                               scv.id_dep_clin_serv,
                               scv.id_room,
                               scv.id_sch_event,
                               scvos.id_sch_consult_vac_oris_slot,
                               scvos.dt_begin,
                               scvos.dt_end
                          INTO io_id_session,
                               io_id_inst,
                               io_id_prof,
                               io_id_dcs,
                               io_id_room,
                               io_id_eve,
                               io_id_slot,
                               io_dt_begin,
                               io_dt_end
                          FROM sch_event e
                          JOIN sch_consult_vacancy scv
                            ON e.id_sch_event = scv.id_sch_event
                          JOIN sch_consult_vac_oris scvo
                            ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
                          JOIN sch_consult_vac_oris_slot scvos
                            ON scvo.id_sch_consult_vacancy = scvos.id_sch_consult_vacancy
                         WHERE e.dep_type = g_surgery_dep_type
                           AND scv.id_institution = io_id_inst
                           AND (io_id_room IS NULL OR nvl(scv.id_room, io_id_room) = io_id_room)
                           AND i_dt_begin BETWEEN scvos.dt_begin AND scvos.dt_end
                           AND i_dt_end BETWEEN scvos.dt_begin AND scvos.dt_end
                           AND scv.flg_status = pk_schedule_bo.g_status_active
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            io_id_session := NULL;
                            io_id_inst    := NULL;
                            io_id_prof    := NULL;
                            io_id_dcs     := NULL;
                            io_id_room    := NULL;
                            io_id_eve     := NULL;
                            io_id_slot    := NULL;
                            io_dt_begin   := NULL;
                            io_dt_end     := NULL;
                    END;
                END IF;
            END IF;
        
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
        END inner_get_slot_data;
    BEGIN
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- validate and get slot data. slot validation might have been made in validate_schedule, but it is needed
        -- here again because some operations like update_schedule may bypass slot validation.
        g_error := 'CALL INNER_GET_SLOT_DATA';
        IF NOT inner_get_slot_data(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_dt_begin    => l_dt_begin,
                                   i_dt_end      => l_dt_end,
                                   io_dt_begin   => l_s_dt_begin,
                                   io_dt_end     => l_s_dt_end,
                                   io_id_room    => l_s_id_room,
                                   io_id_eve     => l_s_id_eve,
                                   io_id_inst    => l_s_id_inst,
                                   io_id_prof    => l_s_id_prof,
                                   io_id_dcs     => l_s_id_dcs,
                                   io_id_slot    => l_s_id_slot,
                                   io_id_session => l_s_id_session,
                                   o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_s_id_slot IS NULL
        THEN
            RAISE l_no_vacancy;
        END IF;
    
        -- Get the event that is actually associated with the vacancies.
        -- It can be a generic event (if the institution has one) or the event itself.
        g_error := 'GET GENERIC EVENT';
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => i_prof.institution,
                                                    i_id_event       => l_s_id_eve,
                                                    o_id_event       => l_id_sch_event,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- check for permission to schedule for this dep_clin_serv, event and professional
        g_error   := 'CHECK PERMISSION TO SCHEDULE';
        l_hasperm := pk_schedule.has_permission(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_dep_clin_serv => i_dcs_list(1),
                                                i_id_sch_event     => l_s_id_eve,
                                                i_id_prof          => i_id_profs_list(1));
        IF l_hasperm = pk_schedule.g_msg_false
        THEN
            RAISE l_no_permission;
        END IF;
    
        -- calcular o flg_sch_type
        IF NOT pk_schedule_common.get_dep_type(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_sch_event => l_id_sch_event,
                                               o_dep_type     => l_dep_type,
                                               o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- get institution where this will be performed
        SELECT d.id_institution
          INTO l_s_id_inst
          FROM dep_clin_serv dcs, department d
         WHERE dcs.id_department = d.id_department
           AND dcs.id_dep_clin_serv = l_s_id_dcs;
    
        l_id_sch          := i_id_schedule;
        l_id_schedule_ref := i_id_schedule_ref;
        IF l_id_sch IS NOT NULL
        THEN
            g_error := 'SELECT SCHEDULE STATUS';
            SELECT s.flg_status
              INTO l_flg_status
              FROM schedule s
             WHERE s.id_schedule = l_id_sch;
        
            -- if schedule status is cancelled (p.e the schedule was cancelled and it is being schedule again) 
            --it is considered the id_schedule = NULL
            IF (l_flg_status = pk_schedule.g_sch_canceled)
            THEN
                l_id_sch          := NULL;
                l_id_schedule_ref := i_id_schedule;
            END IF;
        END IF;
    
        -- Create or update the schedule main data
        IF l_id_sch IS NULL
        THEN
            --inserir na schedule
            g_error := 'CALL PK_SCHEDULE_COMMON.CREATE_SCHEDULE';
            IF NOT pk_schedule_common.create_schedule(i_lang               => i_lang,
                                                      i_id_prof_schedules  => i_prof.id,
                                                      i_id_institution     => i_prof.institution,
                                                      i_id_software        => i_prof.software,
                                                      i_id_patient         => table_number(i_id_patient),
                                                      i_id_dep_clin_serv   => l_s_id_dcs,
                                                      i_id_sch_event       => l_id_sch_event,
                                                      i_id_prof            => i_id_profs_list(1), --l_s_id_prof,
                                                      i_dt_begin           => l_dt_begin,
                                                      i_dt_end             => l_dt_end,
                                                      i_flg_vacancy        => nvl(i_flg_vacancy,
                                                                                  pk_schedule_common.g_sched_vacancy_routine),
                                                      i_flg_status         => pk_schedule.g_status_scheduled,
                                                      i_schedule_notes     => NULL,
                                                      i_id_lang_translator => NULL,
                                                      i_id_lang_preferred  => NULL,
                                                      i_id_reason          => NULL,
                                                      i_id_origin          => NULL,
                                                      i_id_schedule_ref    => l_id_schedule_ref,
                                                      i_id_room            => l_s_id_room,
                                                      i_flg_sch_type       => l_dep_type,
                                                      i_reason_notes       => NULL,
                                                      i_flg_request_type   => NULL,
                                                      i_flg_schedule_via   => NULL,
                                                      i_id_consult_vac     => l_s_id_session,
                                                      o_id_schedule        => o_id_schedule,
                                                      o_occupied           => l_dummy,
                                                      i_ignore_vacancies   => FALSE,
                                                      i_id_episode         => i_id_episode,
                                                      i_id_complaint       => NULL,
                                                      i_id_sch_recursion   => NULL,
                                                      o_error              => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            -- inserir na schedule_sr so se nao existe
            IF l_id_schedule_ref IS NOT NULL
            THEN
                BEGIN
                    SELECT id_schedule_sr
                      INTO l_id_sch_sr
                      FROM schedule_sr
                     WHERE id_schedule = l_id_schedule_ref
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            IF l_id_sch_sr IS NULL
            THEN
                g_error := 'CALL INS_SCHEDULE_SR';
                IF NOT ins_schedule_sr(i_lang                    => i_lang,
                                       i_prof                    => i_prof,
                                       id_schedule_sr_in         => NULL,
                                       id_sched_sr_parent_in     => NULL,
                                       id_schedule_in            => o_id_schedule,
                                       id_episode_in             => i_id_episode,
                                       id_patient_in             => i_id_patient,
                                       duration_in               => NULL,
                                       id_diagnosis_in           => NULL,
                                       id_speciality_in          => NULL,
                                       flg_status_in             => g_active,
                                       flg_sched_in              => g_scheduled,
                                       id_dept_dest_in           => NULL,
                                       prev_recovery_time_in     => NULL,
                                       id_sr_cancel_reason_in    => NULL,
                                       id_prof_cancel_in         => NULL,
                                       notes_cancel_in           => NULL,
                                       id_prof_reg_in            => NULL,
                                       id_institution_in         => l_s_id_inst,
                                       adw_last_update_in        => NULL,
                                       dt_target_tstz_in         => l_dt_begin,
                                       dt_interv_preview_tstz_in => l_dt_begin,
                                       dt_cancel_tstz_in         => NULL,
                                       id_waiting_list_in        => i_id_wl,
                                       flg_temporary_in          => nvl(i_flg_tempor, g_yes),
                                       icu_in                    => i_icu,
                                       notes_in                  => i_notes,
                                       id_schedule_sr_out        => o_id_schedule_sr,
                                       o_error                   => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            ELSE
                -- actualizar a schedule_sr 
                IF NOT upd_schedule_sr(i_lang                    => i_lang,
                                       id_schedule_sr_in         => l_id_sch_sr,
                                       id_schedule_in            => o_id_schedule,
                                       duration_in               => round(trunc(pk_date_utils.get_timestamp_diff(l_dt_end,
                                                                                                                 l_dt_begin),
                                                                                pk_schedule.g_max_decimal_prec) * 1440,
                                                                          0),
                                       flg_status_in             => pk_schedule.g_status_scheduled,
                                       dt_target_tstz_in         => l_dt_begin,
                                       dt_interv_preview_tstz_in => l_dt_begin,
                                       id_waiting_list_in        => i_id_wl,
                                       flg_temporary_in          => i_flg_tempor,
                                       notes_in                  => i_notes,
                                       id_prof_cancel_nin        => FALSE,
                                       id_prof_cancel_in         => NULL,
                                       dt_cancel_tstz_nin        => FALSE,
                                       dt_cancel_tstz_in         => NULL,
                                       notes_cancel_nin          => FALSE,
                                       notes_cancel_in           => NULL,
                                       o_error                   => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END IF;
        ELSE
            -- alert-55881 repor o flg_notification como estava inhantes
            IF NOT pk_schedule_common.get_notification_default(i_lang             => i_lang,
                                                               i_id_dep_clin_serv => l_s_id_dcs,
                                                               o_default_value    => l_notification_default,
                                                               o_error            => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            --actualizar a schedule
            IF NOT pk_schedule_common.alter_schedule(i_lang                  => i_lang,
                                                     i_id_schedule           => l_id_sch,
                                                     i_id_instit_requests    => NULL,
                                                     i_id_instit_requested   => NULL,
                                                     i_id_dcs_requests       => NULL,
                                                     i_id_dcs_requested      => NULL,
                                                     i_id_prof_requests      => NULL,
                                                     i_id_prof_schedules     => i_prof.id,
                                                     i_dt_request_tstz       => NULL,
                                                     i_dt_schedule_tstz      => NULL,
                                                     i_flg_status            => pk_schedule.g_status_scheduled,
                                                     i_dt_begin_tstz         => l_dt_begin,
                                                     i_dt_end_tstz           => l_dt_end,
                                                     i_id_prof_cancel        => NULL,
                                                     i_dt_cancel_tstz        => NULL,
                                                     i_schedule_notes        => NULL,
                                                     i_id_cancel_reason      => NULL,
                                                     i_id_lang_translator    => NULL,
                                                     i_id_lang_preferred     => NULL,
                                                     i_id_sch_event          => l_id_sch_event,
                                                     i_id_reason             => NULL,
                                                     i_reason_notes          => NULL,
                                                     i_id_origin             => NULL,
                                                     i_id_room               => l_s_id_room,
                                                     i_flg_vacancy           => nvl(i_flg_vacancy,
                                                                                    pk_schedule_common.g_sched_vacancy_routine),
                                                     i_flg_urgency           => NULL,
                                                     i_schedule_cancel_notes => NULL,
                                                     i_flg_notification      => l_notification_default,
                                                     i_flg_sch_type          => l_dep_type,
                                                     i_id_schedule_ref       => l_id_schedule_ref,
                                                     i_id_complaint          => NULL,
                                                     i_flg_instructions      => NULL,
                                                     i_id_sch_consult_vac    => l_s_id_session,
                                                     i_id_episode            => i_id_episode,
                                                     o_schedule_rec          => o_r_schedule,
                                                     o_error                 => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            g_error := 'CLEAN SCHEDULE CANCEL COLUMNS';
            UPDATE schedule
               SET id_prof_cancel = NULL, id_cancel_reason = NULL, schedule_cancel_notes = NULL, dt_cancel_tstz = NULL
             WHERE id_schedule = l_id_sch;
        
            -- pegar o id_schedule_sr
            g_error := 'GET ID_SCHEDULE_SR';
            SELECT id_schedule_sr
              INTO l_id_sch_sr
              FROM schedule_sr
             WHERE id_schedule = l_id_sch;
        
            -- actualizar a schedule_sr 
            IF NOT upd_schedule_sr(i_lang                    => i_lang,
                                   id_schedule_sr_in         => l_id_sch_sr,
                                   duration_in               => round(trunc(pk_date_utils.get_timestamp_diff(l_dt_end,
                                                                                                             l_dt_begin),
                                                                            pk_schedule.g_max_decimal_prec) * 1440,
                                                                      0),
                                   dt_target_tstz_in         => l_dt_begin,
                                   dt_interv_preview_tstz_in => l_dt_begin,
                                   id_waiting_list_in        => i_id_wl,
                                   flg_temporary_in          => i_flg_tempor,
                                   notes_in                  => i_notes,
                                   flg_status_in             => pk_schedule.g_status_scheduled,
                                   id_prof_cancel_nin        => FALSE,
                                   id_prof_cancel_in         => NULL,
                                   dt_cancel_tstz_nin        => FALSE,
                                   dt_cancel_tstz_in         => NULL,
                                   notes_cancel_nin          => FALSE,
                                   notes_cancel_in           => NULL,
                                   o_error                   => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            -- inserir na sch_group
            g_error := 'MERGE INTO SCH_GROUP';
            MERGE INTO sch_group g
            USING (SELECT o_r_schedule.id_schedule id_schedule, i_id_patient i_id_pat
                     FROM dual) d
            ON (g.id_schedule = d.id_schedule AND g.id_patient = d.i_id_pat)
            WHEN NOT MATCHED THEN
                INSERT
                    (id_group, id_schedule, id_patient)
                VALUES
                    (seq_sch_group.nextval, d.id_schedule, d.i_id_pat);
        
            -- inserir na sch_resource
            g_error := 'MERGE INTO SCH_RESOURCE';
            MERGE INTO sch_resource r
            USING (SELECT o_r_schedule.id_schedule id_schedule, l_s_id_inst id_ins, i_id_profs_list(1) id_prof
                     FROM dual) d
            ON (r.id_schedule = d.id_schedule AND r.id_professional = d.id_prof)
            WHEN NOT MATCHED THEN
                INSERT
                    (id_sch_resource, id_schedule, id_institution, id_professional, dt_sch_resource_tstz)
                VALUES
                    (seq_sch_resource.nextval, d.id_schedule, d.id_ins, d.id_prof, current_timestamp);
        
            -- actualizar contador dentro da vaga
            -- primeiro pegar a config na vacancy_usage
            /*
                        g_error := 'CHECK_VACANCY_USAGE';
                        -- obter primeiro o i_id_dept a partir do id_dcs_requested. Se nao encontrar deve ir para o WHEN OTHERS
                        SELECT id_department
                          INTO l_id_dept
                          FROM dep_clin_serv d
                         WHERE d.id_dep_clin_serv = nvl(l_s_id_dcs, -1);
                    
                        IF NOT pk_schedule_common.check_vacancy_usage(i_lang           => i_lang,
                                                                      i_id_institution => i_prof.institution,
                                                                      i_id_software    => i_prof.software,
                                                                      i_id_dept        => l_id_dept,
                                                                      i_flg_sch_type   => l_dep_type,
                                                                      o_usage          => l_vacancy_usage,
                                                                      o_sched_w_vac    => l_sched_w_vac,
                                                                      o_edit_vac       => l_edit_vac,
                                                                      o_error          => o_error)
                        THEN
                            IF abs(o_error.ora_sqlcode) IN (100, 1403)
                            THEN
                                RAISE l_no_vac_usage;
                            ELSE
                                ROLLBACK;
                                RETURN FALSE;
                            END IF;
                        END IF;
            */
            IF --l_vacancy_usage AND 
             l_s_id_session IS NOT NULL
            THEN
                -- Try to occupy a vacancy
                g_error := 'CALL SET_VACANT_OCCUPIED';
                IF NOT pk_schedule_common.set_vacant_occupied_by_id_mfr(i_lang       => i_lang,
                                                                        i_id_vacancy => l_s_id_session,
                                                                        o_occupied   => l_occupied,
                                                                        o_error      => o_error)
                THEN
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            END IF;
        
        END IF;
    
        IF (l_id_sch IS NULL)
        THEN
            l_id_schedule := o_id_schedule;
        ELSE
            l_id_schedule := l_id_sch;
        END IF;
    
        -- add room in room_scheduled
        IF NOT upd_room_scheduled(i_lang        => i_lang,
                                  i_id_schedule => l_id_schedule,
                                  i_id_room     => l_s_id_room,
                                  i_prof        => i_prof,
                                  o_error       => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- update WL
        IF NOT pk_wtl_pbl_core.set_schedule(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_id_wtlist   => i_id_wl,
                                            i_id_episode  => i_id_episode,
                                            i_id_schedule => o_id_schedule,
                                            o_error       => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- rebuild slots
        IF NOT create_slots(i_lang                   => i_lang,
                            i_prof                   => i_prof,
                            i_id_sch_consult_vacancy => l_s_id_session,
                            o_error                  => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        o_id_schedule := nvl(o_id_schedule, o_r_schedule.id_schedule);
    
        -- update referral status
        IF (i_id_external_request IS NOT NULL)
        THEN
            g_error := 'CALL PK_REF_EXT_SYS.SET_REF_SCHEDULE with id_external_request: ' || i_id_external_request;
            IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_id_ref   => i_id_external_request,
                                                   i_schedule => o_id_schedule,
                                                   i_notes    => NULL,
                                                   i_episode  => i_id_episode,
                                                   o_error    => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_permission THEN
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_no_permission);
            o_button      := pk_schedule.g_check_button;
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        WHEN l_no_vacancy THEN
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, g_msg_no_avail);
            o_button      := pk_schedule.g_check_button;
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        WHEN l_no_vac_usage THEN
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg         := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_no_vac_usage);
            o_button      := pk_schedule.g_check_button;
            o_flg_show    := g_yes;
            o_flg_proceed := g_no;
            pk_utils.undo_changes;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_schedule_internal;

    /**
    * Wrapper for create_schedule to be used for creating schedules coming from the WL
    * Flash layer should use this one.
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is calling this
    * @param i_dcs_list           list of dcs present in this surgery
    * @param i_id_profs_list      list of professionals participating (direct input)
    * @param i_dt_begin           tentative schedule begin date (direct input)
    * @param i_dt_end             tentative schedule end date (direct input)
    * @param i_flg_tempor         Y=temporary N=definitive (direct input)
    * @param i_id_wl              waiting list id. used for fetching additional data
    * @param i_id_slot            slot id, if this request was dropped into a slot
    * @param i_id_vacancy         vacancy id, if this request was dropped into a session (vacancy)
    * @param i_id_room            Room (direct input?)
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show.    
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Telmo
    * @version  2.5
    * @date     09-04-2009
    */
    FUNCTION create_schedule
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dcs_list      IN table_number,
        i_id_profs_list IN table_number,
        i_dt_begin      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        i_flg_tempor    IN schedule_sr.flg_temporary%TYPE DEFAULT 'Y',
        i_id_wl         IN NUMBER,
        i_id_slot       IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        i_id_session    IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE,
        i_id_room       IN schedule.id_room%TYPE DEFAULT NULL,
        o_id_schedule   OUT schedule.id_schedule%TYPE,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(18) := 'CREATE_SCHEDULE';
        l_id_patient          schedule_sr.id_patient%TYPE;
        l_dcs_list            table_number;
        l_id_profs_list       table_number;
        l_flg_urgency         VARCHAR2(1);
        l_duration            NUMBER;
        l_dpb                 waiting_list.dt_dpb%TYPE;
        l_dpa                 waiting_list.dt_dpa%TYPE;
        l_pref_dt_begin       VARCHAR2(20);
        l_pref_dt_end         VARCHAR2(20);
        l_flg_type            waiting_list.flg_type%TYPE;
        l_flg_status          waiting_list.flg_status%TYPE;
        l_dt_surgery          waiting_list.dt_surgery%TYPE;
        l_min_inform_time     waiting_list.min_inform_time%TYPE;
        l_id_urg_level        waiting_list.id_wtl_urg_level%TYPE;
        l_episodes            pk_wtl_pbl_core.t_rec_episodes;
        l_id_schedule         schedule.id_schedule%TYPE;
        l_id_episode          schedule.id_episode%TYPE;
        l_rec_dcss            pk_wtl_pbl_core.t_rec_dcss;
        i                     INTEGER;
        l_id_external_request waiting_list.id_external_request%TYPE;
    
    BEGIN
        -- fetch WL data
        g_error := 'CALL PK_WTL_PBL_CORE.GET_DATA';
        IF NOT pk_wtl_pbl_core.get_data(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_waiting_list     => i_id_wl,
                                        o_id_patient          => l_id_patient,
                                        o_flg_type            => l_flg_type,
                                        o_flg_status          => l_flg_status,
                                        o_dpb                 => l_dpb,
                                        o_dpa                 => l_dpa,
                                        o_dt_surgery          => l_dt_surgery,
                                        o_min_inform_time     => l_min_inform_time,
                                        o_id_urgency_lev      => l_id_urg_level,
                                        o_id_external_request => l_id_external_request,
                                        o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- obter dados do episodio (dcs, id_schedule e id_episode)
        g_error := 'CALL GET_EPIS_STUFF';
        IF NOT get_epis_stuff(i_lang     => i_lang,
                              i_prof     => i_prof,
                              i_id_wl    => i_id_wl,
                              o_dcs_list => l_dcs_list,
                              o_id_sch   => l_id_schedule,
                              o_id_epis  => l_id_episode,
                              o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- a lista de dcs que vem de fora ainda tem prioridade
        IF i_dcs_list IS NOT NULL
           AND i_dcs_list.exists(1)
           AND TRIM(i_dcs_list(1)) IS NOT NULL
        THEN
            l_dcs_list := i_dcs_list;
        END IF;
    
        -- call the real create
        g_error := 'CALL CREATE_SCHEDULE_INTERNAL';
        IF NOT create_schedule_internal(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_schedule         => l_id_schedule,
                                        i_id_patient          => l_id_patient,
                                        i_dcs_list            => l_dcs_list,
                                        i_id_profs_list       => i_id_profs_list,
                                        i_dt_begin            => i_dt_begin,
                                        i_dt_end              => i_dt_end,
                                        i_flg_tempor          => i_flg_tempor,
                                        i_id_room             => i_id_room,
                                        i_id_episode          => l_id_episode,
                                        i_id_slot             => i_id_slot,
                                        i_id_session          => i_id_session,
                                        i_id_wl               => i_id_wl,
                                        i_id_external_request => l_id_external_request,
                                        o_id_schedule         => o_id_schedule,
                                        o_flg_proceed         => o_flg_proceed,
                                        o_flg_show            => o_flg_show,
                                        o_msg                 => o_msg,
                                        o_msg_title           => o_msg_title,
                                        o_button              => o_button,
                                        o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
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
    END create_schedule;

    /**
    * returns the department clinical services
    *
    * @param i_lang                   Language id   
    * @param i_prof                   Profissional    
    * @param o_dep_clin_servs         Cursor with the clinical service names    
    * @param o_error                  Error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    14-04-2009
    */
    FUNCTION get_dep_clin_servs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_dep_clin_servs OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCHEDULING_STATUS';
    BEGIN
    
        OPEN o_dep_clin_servs FOR
            SELECT to_char(g_all) data,
                   pk_message.get_message(i_lang, g_msg_all_scpecialities) label,
                   g_yes flg_select,
                   1 order_field
              FROM dual
            UNION ALL
            SELECT data, label, flg_select, order_field
              FROM (SELECT DISTINCT to_char(dcs.id_dep_clin_serv) data,
                                    pk_schedule.string_dep_clin_serv(i_lang, dcs.id_dep_clin_serv) label,
                                    g_no flg_select,
                                    2 order_field
                      FROM dep_clin_serv dcs
                      JOIN department d
                        ON dcs.id_department = d.id_department
                      JOIN dept de
                        ON d.id_dept = de.id_dept
                     WHERE d.id_institution = i_prof.institution
                       AND dcs.flg_available = g_yes
                       AND d.flg_type = g_surgery_dep_type
                       AND d.flg_available = g_yes
                       AND de.flg_available = g_yes
                     ORDER BY 2);
    
        -- faltam filtros
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dep_clin_servs);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_dep_clin_servs;

    /**
    * returns the list of surgeons
    *
    * @param i_lang       language id 
    * @param i_prof       Professional Identification  
    * @param o_fst_msg    First option to be shown in the multichoice 
    * @param o_surgeons   Cursor with the surgeons info    
    * @param o_error      error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    07-04-2009
    */
    FUNCTION get_all_surgeons
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_fst_msg  OUT sys_message.desc_message%TYPE,
        o_surgeons OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ALL_SURGEONS';
    BEGIN
        g_error := 'CALL GET_SURGEONS';
        IF (pk_surgery_request.get_surgeons_by_dep_clin_serv(i_lang, i_prof, NULL, NULL, o_surgeons, o_error))
        THEN
            g_error   := 'CALL GET_MESSAGE';
            o_fst_msg := pk_message.get_message(i_lang, g_msg_all_surgeons);
            RETURN TRUE;
        ELSE
            g_error := 'CALL OPEN_MY_CURSOR';
            pk_types.open_my_cursor(o_surgeons);
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_surgeons);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_all_surgeons;

    /** validates a reschedule operation. object being rescheduled comes from clipboard.
    * Determines if the given schedule information follow schedule rules : 
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *  - First appointment should not exist if a first appointment is being created
    *  - Episode validations
    *  - all the rules from validate_schedule
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional doing the reschedule.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_dt_begin               new begin date (direct input)
    * @param i_dt_end                 new end date (direct input)
    * @param i_id_slot                new slot id, if this schedule was dropped into a slot (direct input)
    * @param i_id_session             new vacancy id, if this schedule was dropped into a session (direct input)
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    *
    * @author   Telmo Castro
    * @version  2.5
    * @date     15-04-2009
    */
    FUNCTION validate_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_slot         IN sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE DEFAULT NULL,
        i_id_session      IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(19) := 'VALIDATE_RESCHEDULE';
        l_id_wl        schedule_sr.id_waiting_list%TYPE;
        l_id_sch_event schedule.id_sch_event%TYPE;
        l_id_dcs       schedule.id_dcs_requested%TYPE;
        l_id_prof      sch_resource.id_professional%TYPE;
        l_dummy        VARCHAR2(1);
    BEGIN
        -- fetch original schedule data. if not found jumps to main exception 
        SELECT id_sch_event, id_dcs_requested, sr.id_professional, ssr.id_waiting_list
          INTO l_id_sch_event, l_id_dcs, l_id_prof, l_id_wl
          FROM schedule s
          JOIN schedule_sr ssr
            ON s.id_schedule = ssr.id_schedule
          LEFT JOIN sch_resource sr
            ON ssr.id_schedule = sr.id_schedule
         WHERE s.id_schedule = i_old_id_schedule;
    
        --universal reschedule rules foist
        g_error := 'CALL VALIDATE_RESCHEDULE';
        IF NOT pk_schedule.validate_reschedule(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_old_id_schedule  => i_old_id_schedule,
                                               i_id_dep_clin_serv => NULL, -- nao enviar este para nao validar
                                               i_id_sch_event     => l_id_sch_event,
                                               i_id_prof          => l_id_prof,
                                               i_dt_begin         => i_dt_begin,
                                               o_sv_stop          => l_dummy,
                                               o_flg_proceed      => o_flg_proceed,
                                               o_flg_show         => o_flg_show,
                                               o_msg              => o_msg,
                                               o_msg_title        => o_msg_title,
                                               o_button           => o_button,
                                               o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- now for the oris scheduling rules
        IF NOT validate_schedule(i_lang          => i_lang,
                                 i_prof          => i_prof,
                                 i_dcs_list      => table_number(l_id_dcs),
                                 i_id_profs_list => table_number(l_id_prof),
                                 i_dt_begin      => i_dt_begin,
                                 i_dt_end        => i_dt_end,
                                 i_id_wl         => l_id_wl,
                                 i_id_slot       => i_id_slot,
                                 i_id_session    => i_id_session,
                                 o_flg_proceed   => o_flg_proceed,
                                 o_flg_show      => o_flg_show,
                                 o_msg           => o_msg,
                                 o_msg_title     => o_msg_title,
                                 o_button        => o_button,
                                 o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
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
    END validate_reschedule;

    /*
     * reschedule a session, originating from the clipboard. 
     * this operation allows changes in the begin/end dates.
     * the current schedule is cancelled and a new one created. Column id_schedule_ref in the new 
     * record retains link to ancient schedule.
     *
     * @param i_lang                    Language identifier
     * @param i_prof                    Professional who is rescheduling
     * @param i_old_id_schedule         Identifier of the appointment to be rescheduled
     * @param i_dt_begin                new begin date
     * @param i_dt_end                  new end date
     * @param i_id_slot                 slot id, if this request was dropped into a slot
     * @param i_id_session              vacancy id, if this request was dropped into a session (vacancy)
     * @param o_id_schedule             new schedule id
     * @param o_flg_proceed             Set to 'Y' if there is additional processing needed.
     * @param o_flg_show                Set if a message is displayed or not      
     * @param o_msg                     Message body to be displayed in flash
     * @param o_msg_title               Message title
     * @param o_button                  Buttons to show.
     * @param o_error                   Error message if something goes wrong
     *
     * @return   TRUE if process is ok, FALSE otherwise
     *
     * @author  Telmo
     * @date    16-04-2009
     * @version 2.5
     *
     * UPDATED: Sofia Mendes (allow to change the the professional and the flg_tempor when schedulling)
     * @date    16-12-2009
     * @version 2.6.0
    */
    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_slot         IN sch_consult_vac_mfr_slot.id_sch_consult_vac_mfr_slot%TYPE,
        i_id_session      IN sch_consult_vac_oris.id_sch_consult_vacancy%TYPE DEFAULT NULL,
        i_id_profs_list   IN table_number,
        i_flg_tempor      IN schedule_sr.flg_temporary%TYPE DEFAULT 'Y',
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(19) := 'CREATE_RESCHEDULE';
        l_schedule_cancel_notes schedule.schedule_cancel_notes%TYPE;
        l_message               sys_message.desc_message%TYPE;
        l_dt_begin              TIMESTAMP WITH TIME ZONE;
        l_dt_end                TIMESTAMP WITH TIME ZONE;
        l_sysdate               TIMESTAMP WITH TIME ZONE := current_timestamp;
        l_icu                   schedule_sr.icu%TYPE;
        l_notes                 schedule_sr.notes%TYPE;
    
        --        
        l_id_patient          patient.id_patient%TYPE;
        l_dpb                 waiting_list.dt_dpb%TYPE;
        l_dpa                 waiting_list.dt_dpa%TYPE;
        l_flg_type            waiting_list.flg_type%TYPE;
        l_flg_status          waiting_list.flg_status%TYPE;
        l_dt_surgery          waiting_list.dt_surgery%TYPE;
        l_min_inform_time     waiting_list.min_inform_time%TYPE;
        l_id_urg_level        waiting_list.id_wtl_urg_level%TYPE;
        l_id_external_request waiting_list.id_external_request%TYPE;
        l_id_episode          schedule.id_episode%TYPE;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT sg.id_patient,
                   s.id_dcs_requested,
                   s.id_sch_event,
                   --sr.id_professional,
                   s.flg_vacancy,
                   s.schedule_notes,
                   s.id_room,
                   s.id_episode,
                   s.flg_status,
                   --ssr.flg_temporary,
                   ssr.id_waiting_list
              FROM schedule s
              JOIN schedule_sr ssr
                ON s.id_schedule = ssr.id_schedule
            --LEFT JOIN sch_resource sr ON ssr.id_schedule = sr.id_schedule
              LEFT JOIN sch_group sg
                ON ssr.id_schedule = sg.id_schedule
            
             WHERE s.id_schedule = c_sched.i_old_id_schedule
               AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
    
        l_sched_rec c_sched%ROWTYPE;
    BEGIN
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR dt_begin';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert current date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR sysdate';
        IF NOT pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                        i_inst      => i_prof.institution,
                                                        i_timestamp => l_sysdate,
                                                        o_timestamp => l_sysdate,
                                                        o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- cancel notes to be added to old schedule
        g_error := 'BUILD CANCEL NOTES MESSAGE';
        IF NOT pk_schedule.get_validation_msgs(i_lang         => i_lang,
                                               i_code_msg     => pk_schedule.g_rescheduled_from_to,
                                               i_pkg_name     => g_package_name,
                                               i_replacements => table_varchar(pk_schedule.string_date_hm(i_lang,
                                                                                                          i_prof,
                                                                                                          l_sysdate),
                                                                               pk_schedule.string_date_hm(i_lang,
                                                                                                          i_prof,
                                                                                                          l_dt_begin)),
                                               o_message      => l_schedule_cancel_notes,
                                               o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get old schedule. Must be done before cancel_schedule
        g_error := 'GET OLD SCHEDULE DATA - OPEN c_sched';
        OPEN c_sched(i_old_id_schedule);
        g_error := 'GET OLD SCHEDULE DATA - FETCH c_sched';
        FETCH c_sched
            INTO l_sched_rec;
        g_error := 'GET OLD SCHEDULE DATA - CLOSE c_sched';
        CLOSE c_sched;
    
        -- cancel old schedule and recalc slots if this schedule was attached to a vacancy.
        IF NOT cancel_schedules(i_lang             => i_lang,
                                i_prof             => i_prof,
                                i_id_schedule      => table_number(i_old_id_schedule),
                                i_id_cancel_reason => NULL,
                                i_cancel_notes     => l_schedule_cancel_notes,
                                o_error            => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- fetch WL data
        g_error := 'CALL PK_WTL_PBL_CORE.GET_DATA';
        IF NOT pk_wtl_pbl_core.get_data(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_waiting_list     => l_sched_rec.id_waiting_list,
                                        o_id_patient          => l_id_patient,
                                        o_flg_type            => l_flg_type,
                                        o_flg_status          => l_flg_status,
                                        o_dpb                 => l_dpb,
                                        o_dpa                 => l_dpa,
                                        o_dt_surgery          => l_dt_surgery,
                                        o_min_inform_time     => l_min_inform_time,
                                        o_id_urgency_lev      => l_id_urg_level,
                                        o_id_external_request => l_id_external_request,
                                        o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- create new schedule
        g_error := 'CREATE NEW SCHEDULE';
        IF NOT create_schedule_internal(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_schedule         => NULL,
                                        i_id_patient          => l_sched_rec.id_patient,
                                        i_dcs_list            => table_number(l_sched_rec.id_dcs_requested),
                                        i_id_profs_list       => i_id_profs_list, --table_number(l_sched_rec.id_professional),
                                        i_dt_begin            => i_dt_begin,
                                        i_dt_end              => i_dt_end,
                                        i_flg_tempor          => i_flg_tempor, --l_sched_rec.flg_temporary,
                                        i_flg_vacancy         => l_sched_rec.flg_vacancy,
                                        i_id_room             => l_sched_rec.id_room,
                                        i_id_schedule_ref     => i_old_id_schedule,
                                        i_id_episode          => l_sched_rec.id_episode,
                                        i_id_slot             => i_id_slot,
                                        i_id_session          => i_id_session,
                                        i_id_wl               => l_sched_rec.id_waiting_list,
                                        i_icu                 => l_icu,
                                        i_notes               => l_notes,
                                        i_id_external_request => l_id_external_request,
                                        o_id_schedule         => o_id_schedule,
                                        o_flg_proceed         => o_flg_proceed,
                                        o_flg_show            => o_flg_show,
                                        o_msg                 => o_msg,
                                        o_msg_title           => o_msg_title,
                                        o_button              => o_button,
                                        o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- limpar do clipboard
        IF NOT
            del_sch_clipboard(i_lang => i_lang, i_prof => i_prof, i_id_schedule => i_old_id_schedule, o_error => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
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
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_reschedule;

    /**********************************************************************************************
    * Insert a schedule in clipboard
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule ID
    * @param o_msg                           Message body to be displayed in flash
    * @param o_msg_title                     Message title
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    **********************************************************************************************/
    FUNCTION send_to_clipboard
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_msg         OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SEND_TO_CLIPBOARD';
    
    BEGIN
        g_error := 'INSERT SCH_CLIPBOARD';
        INSERT INTO sch_clipboard
            (id_schedule, id_prof_created, dt_creation)
        VALUES
            (i_id_schedule, i_prof.id, current_timestamp);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN dup_val_on_index THEN
            o_msg_title := pk_message.get_message(i_lang, 'SCH_T499');
            o_msg       := pk_message.get_message(i_lang, 'SCH_T498');
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            -- If function called by FLASH
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END send_to_clipboard;

    /**********************************************************************************************
    * Remove a schedule from clipboard
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule IDs
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    **********************************************************************************************/
    FUNCTION remove_from_clipboard
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'REMOVE_FROM_CLIPBOARD';
    
    BEGIN
        g_error := 'DELETE SCH_CLIPBOARD';
        DELETE FROM sch_clipboard
         WHERE id_schedule IN (SELECT column_value
                                 FROM TABLE(i_id_schedule));
    
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
            -- If function called by FLASH
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END remove_from_clipboard;

    /**********************************************************************************************
    * 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule IDs
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/06
    **********************************************************************************************/
    FUNCTION send_clipboard_to_wl
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SEND_CLIPBOARD_TO_WL';
    
    BEGIN
    
        g_error := 'LOOP';
        IF (i_id_schedule.count > 0)
        THEN
            FOR i IN i_id_schedule.first .. i_id_schedule.last
            LOOP
                IF NOT cancel_schedule(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_schedule      => i_id_schedule(i),
                                       i_id_cancel_reason => NULL,
                                       i_cancel_notes     => NULL,
                                       o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
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
            -- If function called by FLASH
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END send_clipboard_to_wl;

    /**********************************************************************************************
    * Gets schedules from clipboard
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param o_schedules                     Schedules
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/17
    **********************************************************************************************/
    FUNCTION get_sch_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCH_CLIPBOARD';
    BEGIN
    
        g_error := 'SELECT';
        OPEN o_schedules FOR
            SELECT s.id_schedule,
                   extract(hour FROM(s.dt_end_tstz - s.dt_begin_tstz)) || ':' ||
                   to_char(extract(minute FROM(s.dt_end_tstz - s.dt_begin_tstz)), 'FM00') ||
                   pk_message.get_message(i_lang, g_msg_hour_indicator) duration, --'h' duration,
                   extract(hour FROM(s.dt_end_tstz - s.dt_begin_tstz)) || pk_message.get_message(i_lang, 'HOURS_SIGN') || ' ' ||
                   to_char(extract(minute FROM(s.dt_end_tstz - s.dt_begin_tstz)), 'FM00') ||
                   pk_message.get_message(i_lang, 'COMMON_M090') duration_ui,
                   pk_wtl_pbl_core.get_surg_proc_string(i_lang, i_prof, ss.id_waiting_list) desc_surg,
                   pk_wtl_pbl_core.get_danger_cont_string(i_lang, i_prof, s.id_episode, ss.id_waiting_list) cont_danger,
                   pk_wtl_pbl_core.get_pref_time_string(i_lang, i_prof, ss.id_waiting_list) pref_time,
                   pk_wtl_pbl_core.get_ptime_reason_string(i_lang, i_prof, ss.id_waiting_list) pref_time_reason,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, s.id_episode) pat_name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   ss.id_waiting_list
              FROM sch_clipboard sc, schedule s, schedule_sr ss, sch_group sg
             WHERE sc.id_schedule = s.id_schedule
               AND s.id_schedule = sg.id_schedule
               AND s.id_schedule = ss.id_schedule
               AND sc.id_prof_created = i_prof.id
               AND s.id_instit_requested = i_prof.institution
               AND s.id_sch_event = g_surg_sch_event
             ORDER BY s.dt_begin_tstz;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedules);
            -- Unexpected error
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_sch_clipboard;

    /**********************************************************************************************
    * Gets the number of schedules on clipboard
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param o_sch_num                       Number of schedules
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/04/17
    **********************************************************************************************/
    FUNCTION get_sch_clipboard_num
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_sch_num OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sch_num   NUMBER;
        l_func_name VARCHAR2(32) := 'GET_SCH_CLIPBOARD_NUM';
    BEGIN
    
        g_error := 'SELECT';
        SELECT COUNT(1)
          INTO o_sch_num
          FROM sch_clipboard sc, schedule s
         WHERE sc.id_schedule = s.id_schedule
           AND sc.id_prof_created = i_prof.id
           AND s.id_instit_requested = i_prof.institution
           AND s.id_sch_event = g_surg_sch_event;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_sch_clipboard_num;

    /**
    * update an existing schedule
    *
    * @param i_lang                     Language id
    * @param i_prof                     Professional identification
    * @param i_old_id_schedule          ID of schedule that will be updated
    * @param i_id_prof                  Professional ID
    * @param i_dt_begin                 Schedule Start Date
    * @param i_dt_end                   Schedule End Date
    * @param i_flg_temporary_status     Flag temporary ('Y' - temporary, 'N' - final)
    * @param i_flg_vacancy              Flag vacancy
    * @param i_id_episode               Episode ID
    * @param o_id_schedule              Newly generated schedule id 
    * @param o_flg_proceed              Set to 'Y' if there is additional processing needed.
    * @param o_flg_show                 Set if a message is displayed or not      
    * @param o_msg                      Message body to be displayed in flash
    * @param o_msg_title                Message title
    * @param o_button                   Buttons to show.
    * @param o_error                    Error stuff
    *   
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    06-04-2009
    */
    FUNCTION update_schedule
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_old_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_prof              IN sch_resource.id_professional%TYPE,
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        i_flg_temporary_status IN schedule_sr.flg_temporary%TYPE DEFAULT NULL,
        i_flg_vacancy          IN schedule.flg_vacancy%TYPE DEFAULT 'R',
        i_id_episode           IN consult_req.id_episode%TYPE DEFAULT NULL,
        o_id_schedule          OUT schedule.id_schedule%TYPE,
        o_flg_proceed          OUT VARCHAR2,
        o_flg_show             OUT VARCHAR2,
        o_msg                  OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(32) := 'UPDATE_SCHEDULE';
        l_schedule_cancel_notes schedule.schedule_cancel_notes%TYPE;
    
        l_id_dcs_list   table_number := table_number();
        l_id_profs_list table_number := table_number();
        l_rowids        table_varchar;
    
        l_cancel_schedule EXCEPTION;
    
        l_dt_begin TIMESTAMP WITH TIME ZONE;
        l_dt_end   TIMESTAMP WITH TIME ZONE;
    
        l_id_patient          patient.id_patient%TYPE;
        l_dpb                 waiting_list.dt_dpb%TYPE;
        l_dpa                 waiting_list.dt_dpa%TYPE;
        l_flg_type            waiting_list.flg_type%TYPE;
        l_flg_status          waiting_list.flg_status%TYPE;
        l_dt_surgery          waiting_list.dt_surgery%TYPE;
        l_min_inform_time     waiting_list.min_inform_time%TYPE;
        l_id_urg_level        waiting_list.id_wtl_urg_level%TYPE;
        l_id_external_request waiting_list.id_external_request%TYPE;
        l_id_episode          schedule.id_episode%TYPE;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule,
                   s.id_room,
                   s.id_dcs_requested,
                   sg.id_patient,
                   ssr.id_waiting_list,
                   ssr.icu,
                   ssr.notes,
                   s.dt_begin_tstz,
                   s.dt_end_tstz,
                   sr.id_professional,
                   ssr.flg_temporary
              FROM schedule s
              JOIN schedule_sr ssr
                ON s.id_schedule = ssr.id_schedule
              LEFT JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              LEFT JOIN sch_resource sr
                ON s.id_schedule = sr.id_schedule
             WHERE s.id_schedule = c_sched.i_old_id_schedule;
    
        l_sched_rec c_sched%ROWTYPE;
    
        -- Returns a record containing the old schedule's data
        FUNCTION inner_get_old_schedule(i_old_id_schedule schedule.id_schedule%TYPE) RETURN c_sched%ROWTYPE IS
            l_ret c_sched%ROWTYPE;
        BEGIN
            g_error := 'OPEN c_sched';
            OPEN c_sched(inner_get_old_schedule.i_old_id_schedule);
            g_error := 'FETCH c_sched';
            FETCH c_sched
                INTO l_ret;
            g_error := 'CLOSE c_sched';
            CLOSE c_sched;
        
            RETURN l_ret;
        END inner_get_old_schedule;
    
    BEGIN
    
        -- Get old schedule
        g_error     := 'GET OLD SCHEDULE';
        l_sched_rec := inner_get_old_schedule(i_old_id_schedule);
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR dt_begin';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'COMPARE DATES';
        IF (pk_date_utils.compare_dates_tsz(i_prof, l_sched_rec.dt_begin_tstz, l_dt_begin) = 'E' AND
           pk_date_utils.compare_dates_tsz(i_prof, l_sched_rec.dt_end_tstz, l_dt_end) = 'E' AND
           l_sched_rec.id_professional = i_id_prof)
        THEN
            IF (l_sched_rec.flg_temporary != i_flg_temporary_status)
            THEN
                g_error  := 'CALL TS_SCHEDULE_SR.UPD WITH ID_SCHEDULE = ' || i_old_id_schedule;
                l_rowids := table_varchar();
                ts_schedule_sr.upd(flg_temporary_in => i_flg_temporary_status,
                                   where_in         => 'id_schedule = ' || i_old_id_schedule,
                                   rows_out         => l_rowids);
            
                g_error := 'PROCESS UPDATE WITH ID_SCHEDULE = ' || i_old_id_schedule;
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'SCHEDULE_SR',
                                              l_rowids,
                                              o_error,
                                              table_varchar('FLG_TEMPORARY'));
            END IF;
        ELSE
        
            g_error := 'GET CANCEL SCHEDULE';
            -- get cancel notes message
            l_schedule_cancel_notes := pk_message.get_message(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_code_mess => pk_schedule.g_msg_update_schedule);
        
            -- cancel old schedule
            g_error := 'CALL CANCEL_SCHEDULE';
            IF NOT cancel_schedule(i_lang             => i_lang,
                                   i_prof             => i_prof,
                                   i_id_schedule      => i_old_id_schedule,
                                   i_id_cancel_reason => NULL,
                                   i_cancel_notes     => l_schedule_cancel_notes,
                                   o_error            => o_error)
            THEN
                RAISE l_cancel_schedule;
            END IF;
        
            g_error := 'BUILD DEP_CLIN_SERVS LIST';
            l_id_dcs_list.extend(1);
            l_id_dcs_list(1) := l_sched_rec.id_dcs_requested;
        
            g_error := 'BUILD PROFS LIST';
            l_id_profs_list.extend(1);
            l_id_profs_list(1) := i_id_prof;
        
            -- fetch WL data
            g_error := 'CALL PK_WTL_PBL_CORE.GET_DATA';
            IF NOT pk_wtl_pbl_core.get_data(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_waiting_list     => l_sched_rec.id_waiting_list,
                                            o_id_patient          => l_id_patient,
                                            o_flg_type            => l_flg_type,
                                            o_flg_status          => l_flg_status,
                                            o_dpb                 => l_dpb,
                                            o_dpa                 => l_dpa,
                                            o_dt_surgery          => l_dt_surgery,
                                            o_min_inform_time     => l_min_inform_time,
                                            o_id_urgency_lev      => l_id_urg_level,
                                            o_id_external_request => l_id_external_request,
                                            o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- create a new schedule
            g_error := 'CALL CREATE_SCHEDULE_INTERNAL';
            IF NOT create_schedule_internal(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_schedule         => NULL,
                                            i_id_patient          => l_sched_rec.id_patient,
                                            i_dcs_list            => l_id_dcs_list,
                                            i_id_profs_list       => l_id_profs_list,
                                            i_dt_begin            => i_dt_begin,
                                            i_dt_end              => i_dt_end,
                                            i_flg_tempor          => i_flg_temporary_status,
                                            i_flg_vacancy         => i_flg_vacancy,
                                            i_id_room             => l_sched_rec.id_room,
                                            i_id_schedule_ref     => i_old_id_schedule,
                                            i_id_episode          => i_id_episode,
                                            i_id_slot             => NULL,
                                            i_id_session          => NULL,
                                            i_id_wl               => l_sched_rec.id_waiting_list,
                                            i_icu                 => l_sched_rec.icu,
                                            i_notes               => l_sched_rec.notes,
                                            i_id_external_request => l_id_external_request,
                                            o_id_schedule         => o_id_schedule,
                                            o_flg_proceed         => o_flg_proceed,
                                            o_flg_show            => o_flg_show,
                                            o_msg                 => o_msg,
                                            o_msg_title           => o_msg_title,
                                            o_button              => o_button,
                                            o_error               => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            
            ELSE
                IF (o_flg_proceed = g_no)
                THEN
                    ROLLBACK;
                END IF;
            END IF;
        END IF;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_schedule;

    /**
    * returns the surgery scheduling status
    *
    * @param i_lang     language id    
    * @param o_status   Cursor with the requisition status    
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5
    * @date    09-04-2009
    */
    FUNCTION get_requisition_status
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_REQUISITION_STATUS';
    BEGIN
        g_error := 'OPEN O_STATUS CURSOR';
        OPEN o_status FOR
            SELECT to_char(g_all) data,
                   pk_message.get_message(i_lang, g_msg_all_status) label,
                   g_yes flg_select,
                   1 order_field
              FROM dual
            UNION ALL
            SELECT to_char(pk_wtl_pbl_core.g_wtl_search_st_schedule) data,
                   pk_message.get_message(i_lang, g_msg_scheduled) label,
                   g_no flg_select,
                   2 order_field
              FROM dual
            UNION ALL
            SELECT to_char(pk_wtl_pbl_core.g_wtl_search_st_not_schedule) data,
                   pk_message.get_message(i_lang, g_msg_unscheduled) label,
                   g_no flg_select,
                   3 order_field
              FROM dual
            UNION ALL
            SELECT to_char(pk_wtl_pbl_core.g_wtl_search_st_schedule_temp) data,
                   pk_message.get_message(i_lang, g_msg_temporarysch) label,
                   g_no flg_select,
                   4 order_field
              FROM dual;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_status);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_requisition_status;

    /**
    * Cria uma vaga para a agenda do ORIS
    *
    * @param i_lang                     Language id
    * @param i_prof                     Professional identification        
    * @param i_dt_begin                 Initial date
    * @param i_dt_end                   End Date
    * @param i_id_room                  Room id
    * @param i_id_sch_event             Event id (SURGERY event from sch_event table)
    * @param i_id_inst                  Institution ID
    * @param i_id_prof                  Vacancy professional 
    * @param i_id_dcs                   Vacancy Dep_clin_serv
    * @param o_id_slot                  Slot id that match the given parameters       
    * @param o_id_session               Session id that match the given parameters 
    * @param o_error                    Error stuff
    *   
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.x
    * @date    07-05-2009
    */

    FUNCTION create_oris_scheduler_vacancy
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dt_begin       IN sch_consult_vac_oris_slot.dt_begin%TYPE,
        i_dt_end         IN sch_consult_vac_oris_slot.dt_end%TYPE,
        i_id_room        IN sch_consult_vacancy.id_room%TYPE,
        i_id_sch_event   IN sch_event.id_sch_event%TYPE,
        i_id_inst        IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof        IN sch_consult_vacancy.id_prof%TYPE,
        i_flg_urgent_mod IN BOOLEAN,
        i_flg_urgent     IN sch_consult_vac_oris.flg_urgency%TYPE,
        i_id_dcs         IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        o_id_slot        OUT sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        o_id_session     OUT sch_consult_vac_oris.id_sch_consult_vacancy%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'SEARCH_ORIS_SCHEDULER_VACANCY';
        l_id_sch_event sch_event.id_sch_event%TYPE := NULL;
        l_instit       VARCHAR2(50);
        l_func_exception EXCEPTION;
        l_dummy      sch_consult_vac_oris_slot.id_sch_consult_vacancy%TYPE;
        l_flg_urgent sch_consult_vac_oris.flg_urgency%TYPE;
    BEGIN
        g_error := 'SEARCH BY SLOT ID';
        -- Get generic event associated with this appointment
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => l_instit,
                                                    i_id_event       => i_id_sch_event,
                                                    o_id_event       => l_id_sch_event,
                                                    o_error          => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := 'INSERT INTO SCH_CONSULT_VACANCY';
        INSERT INTO sch_consult_vacancy
            (id_sch_consult_vacancy,
             dt_sch_consult_vacancy_tstz,
             id_institution,
             id_prof,
             dt_begin_tstz,
             max_vacancies,
             used_vacancies,
             dt_end_tstz,
             id_dep_clin_serv,
             id_room,
             id_sch_event,
             flg_status)
        VALUES
            (seq_sch_consult_vacancy.nextval,
             current_timestamp,
             i_id_inst,
             i_id_prof,
             i_dt_begin,
             1 + round(dbms_random.value(0, 2)),
             1,
             i_dt_end,
             i_id_dcs,
             i_id_room,
             l_id_sch_event,
             pk_schedule_bo.g_status_active)
        RETURNING id_sch_consult_vacancy INTO o_id_session;
    
        IF (i_flg_urgent_mod)
        THEN
            SELECT decode(MOD(seq_sch_consult_vacancy.currval, 2), 0, 'N', 'Y')
              INTO l_flg_urgent
              FROM dual;
        ELSE
            l_flg_urgent := i_flg_urgent;
        END IF;
    
        INSERT INTO sch_consult_vac_oris
            (id_sch_consult_vacancy, flg_urgency)
        VALUES
            (seq_sch_consult_vacancy.currval, l_flg_urgent);
    
        g_error := 'INSERT INTO SCH_CONSULT_VAC_ORIS_SLOT';
        INSERT INTO sch_consult_vac_oris_slot
            (id_sch_consult_vac_oris_slot, id_sch_consult_vacancy, dt_begin, dt_end)
        VALUES
            (seq_sch_consult_vac_oris_slot.nextval, seq_sch_consult_vacancy.currval, i_dt_begin, i_dt_end)
        RETURNING id_sch_consult_vac_oris_slot INTO o_id_slot;
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
    END create_oris_scheduler_vacancy;

    /**
    * Procura uma vaga existente de acordo com os critérios definidos através dos parâmetros de entrada
    *
    * @param i_lang                     Language id
    * @param i_prof                     Professional identification        
    * @param i_dt_begin                 Initial date
    * @param i_dt_end                   End Date
    * @param i_id_room                  Room id
    * @param i_id_eve                   Event id (SURGERY event from sch_event table)
    * @param i_id_inst                  Institution ID
    * @param i_id_prof                  Vacancy professional 
    * @param i_id_dcs                   Vacancy Dep_clin_serv
    * @param o_id_slot                  Slot id that match the given parameters       
    * @param o_id_session               Session id that match the given parameters 
    * @param o_error                    Error stuff
    *   
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.x
    * @date    07-05-2009
    */

    FUNCTION search_oris_scheduler_vacancy
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dt_begin   IN sch_consult_vac_oris_slot.dt_begin%TYPE,
        i_dt_end     IN sch_consult_vac_oris_slot.dt_end%TYPE,
        i_id_room    IN sch_consult_vacancy.id_room%TYPE,
        i_id_eve     IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_inst    IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof    IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs     IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        o_id_slot    OUT sch_consult_vac_oris_slot.id_sch_consult_vac_oris_slot%TYPE,
        o_id_session OUT sch_consult_vac_oris.id_sch_consult_vacancy%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SEARCH_ORIS_SCHEDULER_VACANCY';
    BEGIN
        g_error := 'SEARCH BY SLOT ID';
    
        BEGIN
            SELECT scv.id_sch_consult_vacancy, scvos.id_sch_consult_vac_oris_slot
              INTO o_id_session, o_id_slot
              FROM sch_event e
              JOIN sch_consult_vacancy scv
                ON e.id_sch_event = scv.id_sch_event
              JOIN sch_consult_vac_oris scvo
                ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
              JOIN sch_consult_vac_oris_slot scvos
                ON scvo.id_sch_consult_vacancy = scvos.id_sch_consult_vacancy
             WHERE e.dep_type = g_surgery_dep_type
               AND scv.id_institution = i_id_inst
               AND scv.flg_status = pk_schedule_bo.g_status_active
               AND (i_id_room IS NULL OR nvl(scv.id_room, i_id_room) = i_id_room)
               AND (i_id_prof IS NULL OR nvl(scv.id_prof, i_id_prof) = i_id_prof)
               AND (i_id_dcs IS NULL OR nvl(scv.id_dep_clin_serv, i_id_dcs) = i_id_dcs)
               AND i_dt_begin BETWEEN scvos.dt_begin AND scvos.dt_end
               AND i_dt_end BETWEEN scvos.dt_begin AND scvos.dt_end
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- se não encontrou, procura apenas pelos atributos obrigatorios
        IF o_id_session IS NULL
        THEN
            BEGIN
                SELECT scv.id_sch_consult_vacancy, scvos.id_sch_consult_vac_oris_slot
                  INTO o_id_session, o_id_slot
                  FROM sch_event e
                  JOIN sch_consult_vacancy scv
                    ON e.id_sch_event = scv.id_sch_event
                  JOIN sch_consult_vac_oris scvo
                    ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
                  JOIN sch_consult_vac_oris_slot scvos
                    ON scvo.id_sch_consult_vacancy = scvos.id_sch_consult_vacancy
                 WHERE e.dep_type = g_surgery_dep_type
                   AND scv.id_institution = i_id_inst
                   AND scv.flg_status = pk_schedule_bo.g_status_active
                   AND (i_id_room IS NULL OR nvl(scv.id_room, i_id_room) = i_id_room)
                   AND i_dt_begin BETWEEN scvos.dt_begin AND scvos.dt_end
                   AND i_dt_end BETWEEN scvos.dt_begin AND scvos.dt_end
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_id_session := NULL;
                    o_id_slot    := NULL;
            END;
        END IF;
    
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
    END search_oris_scheduler_vacancy;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_oris;
/
