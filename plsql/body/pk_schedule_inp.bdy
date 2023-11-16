/*-- Last Change Revision: $Rev: 2027676 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_inp IS

    -- Private Package Constants
    g_yes          CONSTANT VARCHAR2(1) := 'Y';
    g_no           CONSTANT VARCHAR2(1) := 'N';
    g_active       CONSTANT VARCHAR2(1) := 'A';
    g_inactive     CONSTANT VARCHAR2(1) := 'I';
    g_scheduled    CONSTANT VARCHAR2(1) := 'A';
    g_notscheduled CONSTANT VARCHAR2(1) := 'N';

    g_flg_overview        CONSTANT VARCHAR2(1) := 'O';
    g_flg_list_view       CONSTANT VARCHAR2(1) := 'L';
    g_flg_date            CONSTANT VARCHAR2(1) := 'D';
    g_msg_scheduled       CONSTANT VARCHAR2(30) := 'SCH_T481';
    g_msg_unscheduled     CONSTANT VARCHAR2(30) := 'SCH_T482';
    g_msg_temporarysch    CONSTANT VARCHAR2(30) := 'SCH_T483';
    g_msg_nosurgery       CONSTANT VARCHAR2(30) := 'SCH_T561';
    g_msg_all_surg_status CONSTANT VARCHAR2(30) := 'SCH_T562';
    g_all                 CONSTANT NUMBER(2) := -10;
    g_default_end_day     CONSTANT NUMBER(4) := 1439;
    g_default_begin_day   CONSTANT NUMBER(2) := 0;
    g_no_specialty        CONSTANT VARCHAR2(30) := 'NO_SPECIALITY';
    g_multi_specs         CONSTANT VARCHAR2(30) := 'FREE_BEDS_MULTI';
    g_color_prefix        CONSTANT VARCHAR2(30) := '0x';
    g_msg_temporary       CONSTANT VARCHAR2(30) := 'SCH_T416';
    g_msg_final           CONSTANT VARCHAR2(30) := 'SCH_T417';
    g_temporary           CONSTANT VARCHAR2(1) := 'Y';
    g_final               CONSTANT VARCHAR(1) := 'N';
    g_msg_bed             CONSTANT VARCHAR2(30) := 'SCH_T592';
    g_msg_surgery         CONSTANT VARCHAR2(30) := 'SCH_T591';
    g_month_day_format    CONSTANT VARCHAR2(30) := 'Mon DD';
    g_bed_flg_temp        CONSTANT VARCHAR2(30) := 'SCHEDULE_BED.FLG_TEMPORARY';
    g_msg_percentage      CONSTANT VARCHAR2(30) := 'SCH_T755';
    g_nch_capacity_excess CONSTANT VARCHAR2(30) := 'SCH_NCH_CAPACITY_EXCESS';

    /*messages for validate_schedule*/
    g_msg_not_enough_time_header CONSTANT VARCHAR2(8) := 'SCH_T573';
    g_msg_not_enough_time        CONSTANT VARCHAR2(8) := 'SCH_T574';
    g_msg_bad_bed                CONSTANT VARCHAR2(8) := 'SCH_T575';
    g_msg_bed_type_mismatch      CONSTANT VARCHAR2(8) := 'SCH_T577';
    g_msg_room_type_mismatch     CONSTANT VARCHAR2(8) := 'SCH_T578';
    g_msg_ward_mismatch          CONSTANT VARCHAR2(8) := 'SCH_T579';
    g_msg_room_mismatch          CONSTANT VARCHAR2(8) := 'SCH_T580';
    g_msg_adm_ind                CONSTANT VARCHAR2(8) := 'SCH_T581';
    g_msg_pat_unav               CONSTANT VARCHAR2(8) := 'SCH_T466';

    g_msg_hour_indicator CONSTANT VARCHAR2(30) := 'HOURS_SIGN';
    g_msg_dt_admission   CONSTANT VARCHAR2(8) := 'SCH_T593';
    g_msg_id_adm_type    CONSTANT VARCHAR2(8) := 'SCH_T594';
    g_msg_id_dcs         CONSTANT VARCHAR2(8) := 'SCH_T595';
    g_msg_mix_nursing    CONSTANT VARCHAR2(8) := 'SCH_T602';

    /* Surgery Schedule Event */
    g_inp_sch_event CONSTANT NUMBER(2) := 17;

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

    -- Minimum time interval between slots (minutes). Slots with durations below this value will not be create.
    g_sch_min_slot_interval CONSTANT sys_config.id_sys_config%TYPE := 'SCH_MIN_SLOT_INTERVAL';

    /*absolute inferior limit for slot dt_begin */
    g_slot_floor CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := to_timestamp_tz('01/01/2009 00:00:00', 'dd/mm/yyyy hh24:mi:ss');

    /*absolute superior limit for slot dt_end */
    g_slot_ceiling CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := to_timestamp_tz('31/12/2099 00:00:00', 'dd/mm/yyyy hh24:mi:ss');

    /*validate schedule stop error*/
    g_stop_error CONSTANT INTEGER := 500;

    /* bed.flg_status = occupied */
    g_bed_occupied CONSTANT VARCHAR2(1) := 'O';

    /* autopick criteria as in the table*/
    g_ap_crit_adm_location       CONSTANT NUMBER := 1;
    g_ap_crit_nch_needed         CONSTANT NUMBER := 2;
    g_ap_crit_adm_service        CONSTANT NUMBER := 3;
    g_ap_crit_adm_specialty      CONSTANT NUMBER := 4;
    g_ap_crit_adm_physician      CONSTANT NUMBER := 5;
    g_ap_crit_expected_duration  CONSTANT NUMBER := 6;
    g_ap_crit_preparation        CONSTANT NUMBER := 7;
    g_ap_crit_room_type          CONSTANT NUMBER := 8;
    g_ap_crit_mix_nursing        CONSTANT NUMBER := 9;
    g_ap_crit_bed_type           CONSTANT NUMBER := 10;
    g_ap_crit_prefered_room      CONSTANT NUMBER := 11;
    g_ap_crit_surgery_pref_time  CONSTANT NUMBER := 12;
    g_ap_crit_surgery_sug_date   CONSTANT NUMBER := 13;
    g_ap_crit_adm_suggested_date CONSTANT NUMBER := 14;
    g_ap_crit_surgery_date       CONSTANT NUMBER := 15;
    g_ap_crit_unav_periods       CONSTANT NUMBER := 16;

    /* list view constants*/
    /* slot: bed partially free */
    g_flg_color_session_e CONSTANT VARCHAR2(1) := 'E';
    /* full day bed */
    g_flg_color_session_s CONSTANT VARCHAR2(1) := 'F';
    /* empty bed*/
    g_flg_color_session_f CONSTANT VARCHAR2(1) := 'S';
    /* bed partially accupied*/
    g_flg_color_session_h CONSTANT VARCHAR2(1) := 'H';

    g_lv_type_allocation CONSTANT VARCHAR2(30) := 'ALLOCATION';
    g_lv_type_group      CONSTANT VARCHAR2(30) := 'GROUP';
    g_lv_type_slot       CONSTANT VARCHAR2(30) := 'SLOT';
    g_lv_type_schedule   CONSTANT VARCHAR2(30) := 'SCHEDULE';

    g_allocation_icon CONSTANT VARCHAR2(30) := 'WorkflowIcon';
    g_occupied_icon   CONSTANT VARCHAR2(30) := 'WorkflowIcon';

    -- PRIVATE FUNCTIONS

    /*
    * update stats of this bed's room and department in table sch_room_stats.
    * all days between begin and end dates of this schedule will be calculated.
    * For a given day, the rules are:
    * A) patient occupies bed all day = changes total_occupied
    * B) patient has discharge, frees the bed = changes total_free or total_free_with_dcs
    * C) patient is admitted, and stays for next day = changes total_occupied
    * D) patient is admitted and leaves in the same day = changes 
    * E) patient leaves and another one occupies the same day = changes total_occupied
    *
    * @param i_lang                     language id
    * @param i_id_schedule              schedule from which the department, room and period will be extracted
    * @param o_error                    error stuff
    *
    * @return                           success / fail
    *
    * @author   Telmo
    * @version  2.5
    * @since    25-05-2009
    */
    FUNCTION calc_room_stats
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'CALC_ROOM_STATS';
        l_id_bed        schedule_bed.id_bed%TYPE;
        l_id_room       sch_room_stats.id_room%TYPE;
        l_id_department sch_room_stats.id_department%TYPE;
        l_id_dcs        schedule.id_dcs_requested%TYPE;
        l_room_with_dcs NUMBER;
        l_bed_with_dcs  NUMBER;
        l_adm_time      NUMBER;
        l_id_inst       schedule.id_instit_requested%TYPE;
        l_dt_begin      schedule.dt_begin_tstz%TYPE;
        l_dt_end        schedule.dt_end_tstz%TYPE;
        l_day           TIMESTAMP WITH LOCAL TIME ZONE;
        l_beginday      TIMESTAMP WITH LOCAL TIME ZONE;
        l_endday        TIMESTAMP WITH LOCAL TIME ZONE;
        l_occupied      sch_room_stats.total_occupied%TYPE;
        l_free          sch_room_stats.total_free%TYPE;
        l_free_dcs      sch_room_stats.total_free_with_dcs%TYPE;
        l_blocked       sch_room_stats.total_blocked%TYPE := 0;
        l_dummy         NUMBER;
    
    BEGIN
        --get schedule data
        g_error := 'GET SCHEDULE DATA';
        SELECT dt_begin_tstz, dt_end_tstz, id_instit_requested, sb.id_bed, s.id_room, s.id_dcs_requested
          INTO l_dt_begin, l_dt_end, l_id_inst, l_id_bed, l_id_room, l_id_dcs
          FROM schedule s
          JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE s.id_schedule = i_id_schedule;
    
        -- get id department of this bed 
        g_error := 'GET ID DEPARTMENT';
        SELECT d.id_department
          INTO l_id_department
          FROM bed b
          JOIN room r
            ON b.id_room = r.id_room
          JOIN department d
            ON r.id_department = d.id_department
         WHERE b.id_bed = l_id_bed
           AND b.flg_available = g_yes
           AND r.flg_available = g_yes
           AND d.id_institution = l_id_inst
           AND d.flg_available = g_yes;
    
        -- get config sch_admission_time
        g_error := 'GET ADMISSION TIME FOR THIS DEPARTMENT';
        BEGIN
            SELECT nvl(admission_time, 0)
              INTO l_adm_time
              FROM sch_inp_dep_time s
             WHERE s.id_department = l_id_department;
        EXCEPTION
            WHEN OTHERS THEN
                l_adm_time := 0;
        END;
    
        -- extract dates
        pk_date_utils.set_dst_time_check_off;
        l_beginday := pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin);
        l_endday   := pk_date_utils.trunc_insttimezone(i_prof, l_dt_end);
        pk_date_utils.set_dst_time_check_on;
    
        -- iterate all days within the period i_dt_begin -> i_dt_end.
        g_error := 'START LOOP';
        l_day   := l_beginday;
        WHILE l_day <= l_endday
        LOOP
            -- calc occupied beds in this room
            g_error := 'CALC OCCUPIED BEDS';
        
            SELECT SUM(scheduled) occupied,
                   SUM(CASE
                            WHEN scheduled = 0
                                 AND has_dcs = 0 THEN
                             1
                            ELSE
                             0
                        END) free,
                   SUM(CASE
                            WHEN scheduled = 0
                                 AND has_dcs = 1 THEN
                             1
                            ELSE
                             0
                        END) free_dcs
              INTO l_occupied, l_free, l_free_dcs
              FROM (SELECT b.id_bed,
                           CASE
                                WHEN EXISTS (SELECT 1
                                        FROM schedule s
                                        JOIN schedule_bed sb
                                          ON s.id_schedule = sb.id_schedule
                                       WHERE sb.id_bed = b.id_bed
                                         AND s.flg_status <> pk_schedule.g_status_canceled
                                         AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
                                         AND l_day + numtodsinterval(l_adm_time, 'MINUTE') BETWEEN s.dt_begin_tstz AND
                                             s.dt_end_tstz) THEN
                                 1
                                ELSE
                                 0
                            END scheduled,
                           CASE
                                WHEN EXISTS (SELECT 1
                                        FROM bed_dep_clin_serv bdcs
                                       WHERE bdcs.id_bed = b.id_bed
                                         AND bdcs.flg_available = g_yes
                                         AND rownum = 1) THEN
                                 1
                                ELSE
                                 0
                            END has_dcs
                      FROM bed b
                     WHERE b.flg_available = g_yes
                       AND b.id_room = l_id_room);
        
            -- write to table        
            g_error := 'MERGE INTO SCH_ROOM_STATS';
            MERGE INTO sch_room_stats g
            USING (SELECT l_id_department lid, l_id_room lir, to_number(to_char(l_day, 'J')) dd
                     FROM dual) d
            ON (g.id_department = d.lid AND g.id_room = d.lir AND g.dt_day = d.dd)
            WHEN NOT MATCHED THEN
                INSERT
                    (id_department,
                     id_room,
                     dt_day,
                     total_beds,
                     total_blocked,
                     total_occupied,
                     total_free,
                     total_free_with_dcs)
                VALUES
                    (d.lid,
                     d.lir,
                     d.dd,
                     l_occupied + l_free + l_free_dcs + l_blocked,
                     l_blocked,
                     l_occupied,
                     l_free,
                     l_free_dcs)
            WHEN MATCHED THEN
                UPDATE
                   SET g.total_occupied      = l_occupied,
                       g.total_free          = l_free,
                       g.total_free_with_dcs = l_free_dcs,
                       g.total_blocked       = l_blocked,
                       g.total_beds          = l_occupied + l_blocked + l_free + l_free_dcs;
            --next day coming up
            l_day := l_day + INTERVAL '1' DAY;
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
            pk_utils.undo_changes;
            RETURN FALSE;
    END calc_room_stats;

    /**
    * sez if a bed is available within the given period, that is, no schedules inside
    *
    * @param i_lang       language id
    * @param i_id_bed     bed id
    * @param i_dt_begin   start date
    * @param i_dt_end     end date
    * @param o_avail      Y = available  N = not available
    * @param o_error      Error message if something goes wrong
    *
    * @author  Telmo
    * @date     22-05-2009
    * @version  2.5
    *
    * UPDATED: Exclude occupied beds
    * @author  Sofia Mendes
    * @date     27-08-2009
    * @version  2.5.0.5
    */
    FUNCTION is_bed_available
    (
        i_lang     IN language.id_language%TYPE,
        i_id_bed   IN bed.id_bed%TYPE,
        i_dt_begin IN schedule.dt_begin_tstz%TYPE,
        i_dt_end   IN schedule.dt_end_tstz%TYPE,
        o_avail    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'IS_BED_AVAILABLE';
    BEGIN
        g_error := 'IS BED AVAILABLE';
        SELECT g_no
          INTO o_avail
          FROM schedule s
          JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE sb.id_bed = i_id_bed
           AND s.flg_status <> pk_schedule.g_status_canceled
           AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
           AND ((s.dt_begin_tstz > i_dt_begin AND s.dt_begin_tstz < i_dt_end) OR
               (s.dt_end_tstz > i_dt_begin AND s.dt_end_tstz < i_dt_end) OR
               (i_dt_begin > s.dt_begin_tstz AND i_dt_begin < s.dt_end_tstz) OR
               (i_dt_begin > s.dt_begin_tstz AND i_dt_begin < s.dt_end_tstz))
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_avail := g_yes;
        
            g_error := 'CALL pk_bmng_pbl.is_bed_occupied';
            IF NOT pk_bmng_pbl.is_bed_occupied(i_lang     => i_lang,
                                               i_id_bed   => i_id_bed,
                                               i_dt_begin => i_dt_begin,
                                               i_dt_end   => i_dt_end,
                                               o_avail    => o_avail,
                                               o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
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
            RETURN FALSE;
    END is_bed_available;

    /**
    * sez if a bed is available within the given period, this time in terms os slots
    *
    * @param i_lang       language id
    * @param i_id_bed     bed id
    * @param i_dt_begin   start date
    * @param i_dt_end     end date
    * @param o_avail      Y = available  N = not available
    * @param o_error      Error message if something goes wrong
    *
    * @author  Telmo
    * @date     25-05-2009
    * @version  2.5
    */
    FUNCTION is_slot_available
    (
        i_lang     IN language.id_language%TYPE,
        i_id_bed   IN bed.id_bed%TYPE,
        i_dt_begin IN schedule.dt_begin_tstz%TYPE,
        i_dt_end   IN schedule.dt_end_tstz%TYPE,
        o_avail    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'IS_SLOT_AVAILABLE';
    BEGIN
        g_error := 'IS SLOT AVAILABLE';
    
        SELECT g_yes
          INTO o_avail
          FROM sch_bed_slot sbs
         WHERE sbs.id_bed = i_id_bed
           AND i_dt_begin BETWEEN sbs.dt_begin AND sbs.dt_end
           AND i_dt_end BETWEEN sbs.dt_begin AND sbs.dt_end
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_avail := g_no;
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
            RETURN FALSE;
    END is_slot_available;

    -- PUBLIC FUNCTIONS

    /**********************************************************************************************
    * API - insert one row in schedule_bed table
    *
    * @param i_lang                     language id
    * @param id_schedule_in                master id
    * @param id_bed_in                     bed id
    * @param id_waiting_list_in            WL id
    * @param flg_temporary_in              flg_temporary
    * @param flg_conflict_in               flg_conflict
    * @param o_error                      error stuff
    *
    * @return                                success / fail
    *
    * @author   Telmo
    * @version  2.5
    * @since    25-05-2009
    **********************************************************************************************/
    FUNCTION ins_schedule_bed
    (
        i_lang             IN language.id_language%TYPE,
        id_schedule_in     IN schedule_bed.id_schedule%TYPE DEFAULT NULL,
        id_bed_in          IN schedule_bed.id_bed%TYPE DEFAULT NULL,
        id_waiting_list_in IN schedule_bed.id_waiting_list%TYPE DEFAULT NULL,
        flg_temporary_in   IN schedule_bed.flg_temporary%TYPE DEFAULT NULL,
        flg_conflict_in    IN schedule_bed.flg_conflict%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INS_SCHEDULE_BED';
    BEGIN
        g_error := 'INSERT INTO SCHEDULE_BED';
        INSERT INTO schedule_bed
            (id_schedule, id_bed, id_waiting_list, flg_temporary, flg_conflict)
        VALUES
            (id_schedule_in, id_bed_in, id_waiting_list_in, flg_temporary_in, flg_conflict_in);
    
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
    END ins_schedule_bed;

    /**
    * Cancel INP schedule.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_schedule        The schedule id to be canceled
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes
    * @param o_error              Error message if something goes wrong
    *
    * @author                     Jose Antunes
    * @version                    V.2.5
    * @since                      2009/05/21
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
        l_func_name     VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_id_wl         schedule_bed.id_waiting_list%TYPE;
        l_id_bed        schedule_bed.id_bed%TYPE;
        l_flg_conflict  schedule_bed.flg_conflict%TYPE;
        l_list_upd_schs table_number := table_number();
        l_dummy         table_number := table_number();
    
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
        g_error := 'GET WL ID';
        SELECT sb.id_waiting_list, sb.id_bed, sb.flg_conflict
          INTO l_id_wl, l_id_bed, l_flg_conflict
          FROM schedule_bed sb
         WHERE sb.id_schedule = i_id_schedule;
    
        g_error := 'CALL PK_SCHEDULE_COMMON.CANCEL_SCHEDULE';
        IF NOT pk_schedule_common.cancel_schedule(i_lang             => i_lang,
                                                  i_id_professional  => i_prof.id,
                                                  i_id_software      => i_prof.software,
                                                  i_id_schedule      => i_id_schedule,
                                                  i_id_cancel_reason => i_id_cancel_reason,
                                                  i_cancel_notes     => i_cancel_notes,
                                                  i_ignore_vacancies => TRUE,
                                                  o_error            => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL CREATE_SLOTS';
        IF NOT pk_schedule_inp.create_slots(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_id_bed      => l_id_bed,
                                            i_id_schedule => i_id_schedule,
                                            o_error       => o_error)
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
    
        g_error := 'CALL PK_SCHEDULE_INP.CALC_ROOM_STATS';
        IF NOT calc_room_stats(i_lang => i_lang, i_prof => i_prof, i_id_schedule => i_id_schedule, o_error => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- if the canceled schedule has a conflict recalculate conflicts        
        IF (l_flg_conflict = g_yes)
        THEN
            g_error := 'CALL SET_CONFLICTS: ' || i_id_schedule;
            IF NOT set_conflicts(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_id_schedule    => i_id_schedule,
                                 i_flg_conflict   => g_no,
                                 o_list_schedules => l_list_upd_schs,
                                 o_error          => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            --l_nr := l_list_upd_schs.COUNT;
        
            FOR idx IN l_list_upd_schs.first .. l_list_upd_schs.last
            LOOP
                IF (l_list_upd_schs(idx) <> i_id_schedule)
                THEN
                    g_error := 'CALL SET_CONFLICTS: idx: ' || idx || ' id_schedule: ' || i_id_schedule;
                    IF NOT set_conflicts(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_id_schedule    => l_list_upd_schs(idx),
                                         i_flg_conflict   => g_yes,
                                         o_list_schedules => l_dummy,
                                         o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
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
    * Cancel an ORIS schedule.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_schedule        The schedule id to be canceled
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes
    * @param i_transaction_id     Scheduler 3.0 transaction ID
    * @param o_error              Error message if something goes wrong
    *
    * @author                     Jose Antunes
    * @version                    V.2.5
    * @since                      2009/05/21
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(32) := 'CANCEL_SCHEDULE';
        l_id_wl         schedule_bed.id_waiting_list%TYPE;
        l_id_bed        schedule_bed.id_bed%TYPE;
        l_flg_conflict  schedule_bed.flg_conflict%TYPE;
        l_list_upd_schs table_number := table_number();
        l_dummy         table_number := table_number();
    
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
    
        --Scheduler 3.0 transaction ID
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- get schedule data
        g_error := 'GET WL ID';
        SELECT sb.id_waiting_list, sb.id_bed, sb.flg_conflict
          INTO l_id_wl, l_id_bed, l_flg_conflict
          FROM schedule_bed sb
         WHERE sb.id_schedule = i_id_schedule;
    
        g_error := 'CALL PK_SCHEDULE_COMMON.CANCEL_SCHEDULE';
        IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_schedule      => i_id_schedule,
                                           i_id_cancel_reason => i_id_cancel_reason,
                                           i_cancel_notes     => i_cancel_notes,
                                           io_transaction_id  => l_transaction_id,
                                           o_error            => o_error)
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL CREATE_SLOTS';
        IF NOT pk_schedule_inp.create_slots(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_id_bed      => l_id_bed,
                                            i_id_schedule => i_id_schedule,
                                            o_error       => o_error)
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
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
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_SCHEDULE_INP.CALC_ROOM_STATS';
        IF NOT calc_room_stats(i_lang => i_lang, i_prof => i_prof, i_id_schedule => i_id_schedule, o_error => o_error)
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- if the canceled schedule has a conflict recalculate conflicts        
        IF (l_flg_conflict = g_yes)
        THEN
            g_error := 'CALL SET_CONFLICTS: ' || i_id_schedule;
            IF NOT set_conflicts(i_lang           => i_lang,
                                 i_prof           => i_prof,
                                 i_id_schedule    => i_id_schedule,
                                 i_flg_conflict   => g_no,
                                 o_list_schedules => l_list_upd_schs,
                                 o_error          => o_error)
            THEN
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            --l_nr := l_list_upd_schs.COUNT;
        
            FOR idx IN l_list_upd_schs.first .. l_list_upd_schs.last
            LOOP
                IF (l_list_upd_schs(idx) <> i_id_schedule)
                THEN
                    g_error := 'CALL SET_CONFLICTS: idx: ' || idx || ' id_schedule: ' || i_id_schedule;
                    IF NOT set_conflicts(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_id_schedule    => l_list_upd_schs(idx),
                                         i_flg_conflict   => g_yes,
                                         o_list_schedules => l_dummy,
                                         o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
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
        
            g_error := 'CALL PK_REF_EXT_SYS.UPDATE_REFERRAL_STATUS with id_external_request: ' || l_id_external_request;
            IF NOT pk_ref_ext_sys.update_referral_status(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_ext_req  => l_id_external_request,
                                                         i_status   => pk_ref_constant.g_p1_status_a,
                                                         i_notes    => NULL,
                                                         i_schedule => i_id_schedule,
                                                         i_episode  => l_id_episode,
                                                         o_error    => o_error)
            
            THEN
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
        --        
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_schedule;

    -- Functions and Procedures
    /******************************************************************************
    *  Add or updates an element into a table of type t_tab_sch_inp_lv.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_type              Type identification (Schedule, Allocation, Slot, Group)
    *  @param  i_id_bed            Bed identifier   
    *  @param  i_id_patient        Patient identifier
    *  @param  i_dt_begin          Begin date
    *  @param  i_dt_end            End date
    *  @param  i_begin_hour        Begin hour
    *  @param  i_end_hour          End hour
    *  @param  i_icon              Icon description
    *  @param  i_order             Relative order to help the list view ordering
    *  @param  i_id_schedule       Schedule identifier
    *  @param  i_flg_color_session Flag that indicates the color
    *  @param  i_mode              1-insert mode; 2-update mode
    *  @param  io_idx              Position to insert/update 
    *  @param  io_tab              Altered table
    *  @param  o_error             Error stuff
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.5.0.5
    *  @since                      2009-08-17
    ******************************************************************************/
    FUNCTION add_tab_element
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_type              IN VARCHAR2,
        i_id_bed            IN bed.id_bed%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_dt_begin          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_begin_hour        IN VARCHAR2,
        i_end_hour          IN VARCHAR2,
        i_icon              IN VARCHAR2,
        i_order             IN NUMBER DEFAULT 1,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_flg_color_session VARCHAR2,
        i_mode              IN NUMBER DEFAULT 1, -- 1->insert new element; 2-> update an element 
        io_idx              IN OUT NUMBER,
        io_tab              IN OUT t_tab_sch_inp_lv,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30) := 'ADD_TAB_ELEMENT';
        l_lv_data_rec t_rec_sch_inp_lv;
    BEGIN
        g_error       := 'ADD_ELEMENT: type-> ' || i_type || ' begin_hour: ' || i_begin_hour || ' end_hour: ' ||
                         i_end_hour;
        l_lv_data_rec := t_rec_sch_inp_lv(i_type,
                                          i_id_bed,
                                          i_id_patient,
                                          i_dt_begin,
                                          i_dt_end,
                                          i_begin_hour,
                                          i_end_hour,
                                          i_icon,
                                          i_order,
                                          i_id_schedule,
                                          i_flg_color_session);
        IF (i_mode = 1)
        THEN
            io_tab.extend(1);
            io_tab(io_idx) := l_lv_data_rec;
            io_idx := io_idx + 1;
        ELSE
            io_tab(io_idx) := l_lv_data_rec;
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
    END add_tab_element;

    /******************************************************************************
    *  Returns the status icon
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_type              Indicates if it is an allocation or a schedule
    *  @param  i_id_schedule       Schedule identifier   
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.5.0.5
    *  @since                      2009-08-17
    ******************************************************************************/
    FUNCTION get_status_icon
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type        IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30) := 'GET_STATUS_ICON';
        l_flg_conflict  schedule_bed.flg_conflict%TYPE;
        l_flg_status    schedule.flg_status%TYPE;
        l_flg_temporary schedule_bed.flg_temporary%TYPE;
    BEGIN
    
        IF (i_type = g_lv_type_allocation)
        THEN
            RETURN pk_schedule.g_icon_prefix || g_allocation_icon;
        ELSIF (i_type = g_lv_type_schedule)
        THEN
            SELECT sb.flg_temporary, sb.flg_conflict, s.flg_status
              INTO l_flg_temporary, l_flg_conflict, l_flg_status
              FROM schedule s
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
             WHERE sb.id_schedule = i_id_schedule;
        
            /* 
            pk_schedule.g_icon_prefix ||
                  decode(l_flg_temporary,
                         g_yes,
                         --temporary
                         decode(l_flg_conflict,
                                g_yes,
                                --temporary with conflict
                                pk_schedule.g_sched_icon_temp_conflict,
                                --temporary with no conflict
                                pk_schedule.g_sched_icon_temp),
                         --final (permanent)
                         decode(l_flg_conflict,
                                g_yes,
                                --final with conflict
                                pk_schedule.g_sched_icon_perm_conflict,
                                --final with no conflict
                                pk_sysdomain.get_img(i_lang, pk_schedule.g_schedule_flg_status_domain, l_flg_status)));*/
        
            IF (l_flg_temporary = g_yes)
            THEN
                IF (l_flg_conflict = g_yes)
                THEN
                    --temporary with conflict
                    RETURN pk_schedule.g_icon_prefix || pk_schedule.g_sched_icon_temp_conflict;
                ELSE
                    --temporary with no conflict
                    RETURN pk_schedule.g_icon_prefix || pk_schedule.g_sched_icon_temp;
                END IF;
            
            ELSE
                --final (permanent)
            
                IF (l_flg_conflict = g_yes)
                THEN
                    --final with conflict
                    RETURN pk_schedule.g_icon_prefix || pk_schedule.g_sched_icon_perm_conflict;
                ELSE
                    --final with no conflict
                    RETURN pk_schedule.g_icon_prefix || pk_sysdomain.get_img(i_lang,
                                                                             pk_schedule.g_schedule_flg_status_domain,
                                                                             l_flg_status);
                END IF;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    
    END get_status_icon;

    /******************************************************************************
    *  Returns the clinical service desciption of the schedule or the bed
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_type              Indicates if it is an allocation or a schedule
    *  @param  i_id_schedule       Schedule identifier   
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.5.0.5
    *  @since                      2009-08-17
    ******************************************************************************/
    FUNCTION get_clinical_service_desc
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE,
        i_id_dcs IN schedule.id_dcs_requested%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_CLINICAL_SERVICE_DESC';
    BEGIN
        IF (i_id_dcs IS NULL)
        THEN
            RETURN pk_bmng.get_bed_dep_clin_serv(i_lang, i_prof, i_id_bed);
        ELSE
            RETURN pk_schedule.string_dep_clin_serv(i_lang, i_id_dcs);
        END IF;
    
    END get_clinical_service_desc;

    /******************************************************************************
    *  Auxiliary function to calculate the slots between two schedules and/or allocations
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_prev_dt_begin     Start date of the first schedule/allocation
    *  @param  i_prev_dt_end       End date of the first schedule/allocation
    *  @param  i_dt_begin          Start date of the 2nd schedule/allocation
    *  @param  i_dt_end            End date of the 2nd schedule/allocation
    *  @param  i_date_tz_local     Date of the screen
    *  @param  io_has_slot         Indicate if it has a slot in this day
    *  @param  io_tab_lv_data      List of schedules/allocations, groups and slots of the current day in this bed
    *  @param  i_nr_elems_same_bed Nr pf schedules/allocations in this bed in this day
    *  @param  i_id_bed            Bed identifier
    *  @param  io_prev_sch_end_dts List of schedules of the current day in this bed
    *  @param  o_error             Error stuff
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.5.0.5
    *  @since                      2009-09-17
    ******************************************************************************/
    FUNCTION calc_slot
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_prev_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prev_dt_end       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_begin          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_date_tz_local     IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_has_slot         IN OUT BOOLEAN,
        io_tab_lv_data      IN OUT t_tab_sch_inp_lv,
        i_nr_elems_same_bed IN NUMBER,
        i_id_bed            IN bed.id_bed%TYPE,
        io_idx              IN OUT NUMBER,
        io_prev_sch_end_dts IN OUT table_timestamp_tz,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_has_lower    BOOLEAN := FALSE;
        l_greater_date TIMESTAMP WITH TIME ZONE;
    
        FUNCTION inner_greater_dt(i_tab_dates table_timestamp_tz) RETURN TIMESTAMP
            WITH LOCAL TIME ZONE IS
            l_date TIMESTAMP WITH TIME ZONE;
        BEGIN
            IF (i_tab_dates IS NOT NULL AND i_tab_dates.exists(1))
            THEN
                FOR idx IN i_tab_dates.first .. i_tab_dates.last
                LOOP
                    IF (l_date IS NULL OR i_tab_dates(idx) > l_date)
                    THEN
                        IF (i_tab_dates(idx) > i_date_tz_local + 1)
                        THEN
                            l_date := i_date_tz_local + 1;
                        ELSE
                            l_date := i_tab_dates(idx);
                        END IF;
                    END IF;
                END LOOP;
            END IF;
            RETURN l_date;
        END inner_greater_dt;
    
    BEGIN
        IF (i_prev_dt_begin <= i_date_tz_local AND
           to_char(i_prev_dt_begin, 'yyyymmddhh24miss') = to_char(i_date_tz_local, 'yyyymmddhh24miss') AND
           (i_prev_dt_end >= i_date_tz_local + 1))
        THEN
            RETURN TRUE;
        END IF;
    
        -- slot no inicio do dia        
        IF (i_prev_dt_begin IS NULL AND i_dt_begin > i_date_tz_local)
        THEN
            pk_date_utils.set_dst_time_check_off;
            IF NOT add_tab_element(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_type              => g_lv_type_slot, --'SLOT',
                                   i_id_bed            => i_id_bed,
                                   i_id_patient        => NULL,
                                   i_dt_begin          => i_date_tz_local,
                                   i_dt_end            => NULL,
                                   i_begin_hour        => '00:00' || pk_message.get_message(i_lang, g_msg_hour_indicator),
                                   i_end_hour          => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                           i_dt_begin,
                                                                                           i_prof.institution,
                                                                                           i_prof.software),
                                   i_icon              => pk_schedule.g_icon_prefix || 'ExtendIcon',
                                   i_order             => 3,
                                   i_id_schedule       => NULL,
                                   i_flg_color_session => g_flg_color_session_e,
                                   io_idx              => io_idx,
                                   io_tab              => io_tab_lv_data,
                                   o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
            pk_date_utils.set_dst_time_check_on;
            io_has_slot := TRUE;
            RETURN TRUE;
        END IF;
    
        --slot entre dois agendamentos/alocações
        IF (i_dt_begin > i_prev_dt_end)
        THEN
            pk_date_utils.set_dst_time_check_off;
            IF NOT add_tab_element(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_type              => g_lv_type_slot, --'SLOT',
                                   i_id_bed            => i_id_bed,
                                   i_id_patient        => NULL,
                                   i_dt_begin          => NULL,
                                   i_dt_end            => NULL,
                                   i_begin_hour        => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                           i_prev_dt_end,
                                                                                           i_prof.institution,
                                                                                           i_prof.software),
                                   i_end_hour          => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                           i_dt_begin,
                                                                                           i_prof.institution,
                                                                                           i_prof.software),
                                   i_icon              => pk_schedule.g_icon_prefix || 'ExtendIcon',
                                   i_order             => 3,
                                   i_id_schedule       => NULL,
                                   i_flg_color_session => g_flg_color_session_e,
                                   io_idx              => io_idx,
                                   io_tab              => io_tab_lv_data,
                                   o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
            pk_date_utils.set_dst_time_check_on;
            io_has_slot := TRUE;
            RETURN TRUE;
        END IF;
    
        --slot no final do dia        
        IF (i_dt_begin IS NULL AND i_prev_dt_end < i_date_tz_local + 1)
        THEN
        
            l_greater_date := inner_greater_dt(io_prev_sch_end_dts);
        
            IF (l_greater_date < i_date_tz_local + 1)
            THEN
                pk_date_utils.set_dst_time_check_off;
                IF NOT
                    add_tab_element(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_type              => g_lv_type_slot, --'SLOT',
                                    i_id_bed            => i_id_bed,
                                    i_id_patient        => NULL,
                                    i_dt_begin          => i_prev_dt_end,
                                    i_dt_end            => NULL,
                                    i_begin_hour        => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                            l_greater_date,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                    i_end_hour          => '24:00' || pk_message.get_message(i_lang, g_msg_hour_indicator),
                                    i_icon              => pk_schedule.g_icon_prefix || 'ExtendIcon',
                                    i_order             => 3,
                                    i_id_schedule       => NULL,
                                    i_flg_color_session => g_flg_color_session_e,
                                    io_idx              => io_idx,
                                    io_tab              => io_tab_lv_data,
                                    o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                pk_date_utils.set_dst_time_check_on;
                io_has_slot := TRUE;
            END IF;
        END IF;
    
        RETURN TRUE;
    END calc_slot;

    /******************************************************************************
    *  Auxiliary function to calculate the slots and groups given the list of occupation to a bed to be presented on the 
    * list view
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_date_tz_local     Date
    *  @param  io_tab_lv_data      Output data
    *  @param  i_nr_elems_same_bed Number of occupations (schedules+allocations) in the bed
    *  @param  i_id_bed            Bed identifier
    *  @param  i_has_full_day      Indicates if there is a full day occupation
    *  @param  io_idx              Next index to be occupied in the output table
    *  @param  o_error             Error stuff
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.5.0.5
    *  @since                      2009-08-17
    *
    ******************************************************************************/
    FUNCTION calc_groups_and_slots
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_date_tz_local     IN TIMESTAMP WITH LOCAL TIME ZONE,
        io_tab_lv_data      IN OUT t_tab_sch_inp_lv,
        i_nr_elems_same_bed IN NUMBER,
        i_id_bed            IN bed.id_bed%TYPE,
        i_has_full_day      IN BOOLEAN,
        io_idx              IN OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(30) := 'CALC_GROUPS';
        l_reg_type_str VARCHAR2(30);
        l_schedule     schedule.id_schedule%TYPE;
    
        l_prev_dt_begin TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_prev_dt_end   TIMESTAMP WITH LOCAL TIME ZONE := NULL;
    
        l_id_patient  patient.id_patient%TYPE := NULL;
        l_dt_begin    TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_dt_end      TIMESTAMP WITH LOCAL TIME ZONE := NULL;
        l_lv_data_rec t_rec_sch_inp_lv;
    
        l_update_idx NUMBER;
        l_has_slot   BOOLEAN := FALSE;
    
        l_schedules        pk_types.cursor_type;
        l_prev_sch_end_dts table_timestamp_tz := table_timestamp_tz();
    
        l_count PLS_INTEGER := 0;
    
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'LOOP THROUTH l_occupations cursor: ';
        IF (i_nr_elems_same_bed > 1 AND i_has_full_day = TRUE)
        THEN
            FOR i IN 1 .. i_nr_elems_same_bed
            LOOP
                l_lv_data_rec := io_tab_lv_data(io_idx - i);
                IF (l_lv_data_rec.icon = pk_schedule.g_icon_prefix || 'DetailInternmentIcon')
                THEN
                    l_update_idx := io_idx - i;
                    IF NOT add_tab_element(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_type              => l_lv_data_rec.type,
                                           i_id_bed            => i_id_bed,
                                           i_id_patient        => l_lv_data_rec.id_patient,
                                           i_dt_begin          => l_lv_data_rec.dt_begin,
                                           i_dt_end            => l_lv_data_rec.dt_end,
                                           i_begin_hour        => '00:00' ||
                                                                  pk_message.get_message(i_lang, g_msg_hour_indicator),
                                           i_end_hour          => '24:00' ||
                                                                  pk_message.get_message(i_lang, g_msg_hour_indicator),
                                           i_icon              => pk_schedule.g_icon_prefix || 'ExtendIcon',
                                           i_order             => 3,
                                           i_id_schedule       => l_lv_data_rec.elem_id,
                                           i_flg_color_session => g_flg_color_session_f,
                                           i_mode              => 2,
                                           io_idx              => l_update_idx,
                                           io_tab              => io_tab_lv_data,
                                           o_error             => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'OPEN l_schedules CURSOR';
        OPEN l_schedules FOR
            SELECT tab.type reg_type_str, tab.elem_id, tab.id_patient, tab.dt_begin, tab.dt_end
              FROM TABLE(io_tab_lv_data) tab
             WHERE tab.id_bed = i_id_bed
               AND (tab.type = g_lv_type_schedule OR tab.type = g_lv_type_allocation)
             ORDER BY begin_hour, end_hour;
    
        LOOP
            g_error := 'LOOP THROUTH l_occupations cursor: ';
            FETCH l_schedules
                INTO l_reg_type_str, l_schedule, l_id_patient, l_dt_begin, l_dt_end;
            EXIT WHEN l_schedules%NOTFOUND;
        
            IF NOT calc_slot(i_lang              => i_lang,
                             i_prof              => i_prof,
                             i_prev_dt_begin     => l_prev_dt_begin,
                             i_prev_dt_end       => l_prev_dt_end,
                             i_dt_begin          => l_dt_begin,
                             i_dt_end            => l_dt_end,
                             i_date_tz_local     => i_date_tz_local,
                             io_has_slot         => l_has_slot,
                             io_tab_lv_data      => io_tab_lv_data,
                             i_nr_elems_same_bed => i_nr_elems_same_bed,
                             i_id_bed            => i_id_bed,
                             io_idx              => io_idx,
                             io_prev_sch_end_dts => l_prev_sch_end_dts,
                             o_error             => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            l_prev_dt_begin := l_dt_begin;
            l_prev_dt_end   := l_dt_end;
        
            l_prev_sch_end_dts.extend(1);
            l_prev_sch_end_dts(l_prev_sch_end_dts.last) := l_prev_dt_end;
        
            l_count := l_count + 1;
        END LOOP;
    
        IF l_count > 0
        THEN
            IF NOT calc_slot(i_lang              => i_lang,
                        i_prof              => i_prof,
                        i_prev_dt_begin     => CASE
                                                   WHEN l_prev_dt_begin IS NULL THEN
                                                    l_dt_begin
                                                   ELSE
                                                    l_prev_dt_begin
                                               END,
                        i_prev_dt_end       => CASE
                                                   WHEN l_prev_dt_end IS NULL THEN
                                                    l_dt_end
                                                   ELSE
                                                    l_prev_dt_end
                                               END,
                        i_dt_begin          => NULL,
                        i_dt_end            => NULL,
                        i_date_tz_local     => i_date_tz_local,
                        io_has_slot         => l_has_slot,
                        io_tab_lv_data      => io_tab_lv_data,
                        i_nr_elems_same_bed => i_nr_elems_same_bed,
                        i_id_bed            => i_id_bed,
                        io_idx              => io_idx,
                        io_prev_sch_end_dts => l_prev_sch_end_dts,
                        o_error             => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF (i_nr_elems_same_bed > 1 OR l_has_slot = TRUE)
        THEN
            IF NOT add_tab_element(i_lang              => i_lang,
                              i_prof              => i_prof,
                              i_type              => g_lv_type_group, --'GROUP',
                              i_id_bed            => i_id_bed,
                              i_id_patient        => NULL,
                              i_dt_begin          => NULL,
                              i_dt_end            => NULL,
                              i_begin_hour        => '00:00' || pk_message.get_message(i_lang, g_msg_hour_indicator),
                              i_end_hour          => '24:00' || pk_message.get_message(i_lang, g_msg_hour_indicator),
                              i_icon              => pk_schedule.g_icon_prefix || 'BedOccupiedOverbookingIcon',
                              i_order             => 1,
                              i_id_schedule       => NULL,
                              i_flg_color_session => CASE
                                                         WHEN l_has_slot = TRUE THEN
                                                          g_flg_color_session_h
                                                         ELSE
                                                          g_flg_color_session_s
                                                     END,
                              io_idx              => io_idx,
                              io_tab              => io_tab_lv_data,
                              o_error             => o_error)
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
    END calc_groups_and_slots;

    /******************************************************************************
    *  Consctructs a table with the occupations (schedules + allocations), slots and groups.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_occupations       Cursor with the schedules and the allocations
    *  @param  i_date_tz_local     Date
    *  @param  o_tab_lv_data       Output data
    *  @param  o_error             Error stuff
    *
    *  @return                     varchar2
    *
    *  @author                     Sofia Mendes
    *  @version                    2.5.0.5
    *  @since                      2009-08-17
    *
    ******************************************************************************/
    FUNCTION calc_occupations_and_groups
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_occupations   IN pk_types.cursor_type,
        i_date_tz_local IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_tab_lv_data   OUT t_tab_sch_inp_lv,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(30) := 'CALC_GROUPS';
        l_reg_type_str VARCHAR2(30);
        l_schedule     schedule.id_schedule%TYPE;
    
        l_lv_data_rec t_rec_sch_inp_lv;
        l_tab_lv_data t_tab_sch_inp_lv := t_tab_sch_inp_lv();
        --l_tab_lv_data_bed      t_tab_sch_inp_lv := t_tab_sch_inp_lv();
        l_id_bed     bed.id_bed%TYPE;
        l_id_patient patient.id_patient%TYPE;
        l_dt_begin   TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end     TIMESTAMP WITH LOCAL TIME ZONE;
        --l_update_idx           NUMBER;
        l_prev_id_bed          bed.id_bed%TYPE := NULL;
        l_prev_id_patient      patient.id_patient%TYPE := NULL;
        idx                    NUMBER := 1;
        l_has_group            BOOLEAN := FALSE;
        l_has_full_day         BOOLEAN := FALSE;
        l_count_elems_same_bed PLS_INTEGER := 0;
    
        l_previous_schedule   schedule.id_schedule%TYPE;
        l_previous_id_bed     bed.id_bed%TYPE;
        l_previous_id_patient patient.id_patient%TYPE;
        l_previous_dt_begin   TIMESTAMP WITH LOCAL TIME ZONE;
        l_previous_dt_end     TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        -- collect all schedules and allocations
        LOOP
            FETCH i_occupations
                INTO l_reg_type_str, l_schedule, l_id_bed, l_id_patient, l_dt_begin, l_dt_end;
            EXIT WHEN i_occupations%NOTFOUND;
            g_error := 'LOOP THROUTH l_occupations cursor: l_schedule: ' || l_schedule;
        
            IF (l_previous_schedule = l_schedule AND l_previous_id_bed = l_id_bed AND
               l_previous_id_patient = l_id_patient AND l_previous_dt_begin = l_dt_begin AND
               l_previous_dt_end = l_dt_end)
            THEN
                NULL;
            ELSE
            
                IF (idx > 1)
                THEN
                    l_lv_data_rec := l_tab_lv_data(idx - 1);
                
                    l_prev_id_bed := l_lv_data_rec.id_bed;
                
                    IF (l_lv_data_rec.id_patient IS NOT NULL)
                    THEN
                        l_prev_id_patient := l_lv_data_rec.id_patient;
                    END IF;
                END IF;
            
                IF (l_id_bed <> l_prev_id_bed AND l_prev_id_bed IS NOT NULL)
                THEN
                    g_error := 'CALL  calc_groups_and_slots';
                    IF NOT calc_groups_and_slots(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_date_tz_local     => i_date_tz_local,
                                                 io_tab_lv_data      => l_tab_lv_data,
                                                 i_nr_elems_same_bed => l_count_elems_same_bed,
                                                 i_id_bed            => l_prev_id_bed,
                                                 i_has_full_day      => l_has_full_day,
                                                 io_idx              => idx,
                                                 o_error             => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                    l_has_full_day         := FALSE;
                    l_count_elems_same_bed := 0;
                
                END IF;
            
                l_count_elems_same_bed := l_count_elems_same_bed + 1;
            
                IF (l_dt_begin <= i_date_tz_local OR
                   to_char(l_dt_begin, 'yyyymmddhh24miss') = to_char(i_date_tz_local, 'yyyymmddhh24miss'))
                THEN
                    IF (l_dt_end >= i_date_tz_local + 1 OR
                       to_char(l_dt_end, 'yyyymmddhh24miss') = to_char(i_date_tz_local + 1, 'yyyymmddhh24miss'))
                    THEN
                        -- full day schedule or allocation
                        IF NOT add_tab_element(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_type              => l_reg_type_str,
                                          i_id_bed            => l_id_bed,
                                          i_id_patient        => l_id_patient,
                                          i_dt_begin          => l_dt_begin,
                                          i_dt_end            => l_dt_end,
                                          i_begin_hour        => '00:00' || pk_message.get_message(i_lang, g_msg_hour_indicator),
                                          i_end_hour          => '24:00' || pk_message.get_message(i_lang, g_msg_hour_indicator),
                                          i_icon              => CASE
                                                                     WHEN (l_has_group = FALSE) THEN
                                                                      pk_schedule.g_icon_prefix || 'DetailInternmentIcon'
                                                                     ELSE
                                                                      pk_schedule.g_icon_prefix || 'ExtendIcon'
                                                                 END,
                                          i_order             => 3,
                                          i_id_schedule       => l_schedule,
                                          i_flg_color_session => g_flg_color_session_s,
                                          io_idx              => idx,
                                          io_tab              => l_tab_lv_data,
                                          o_error             => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    
                        l_has_full_day := TRUE;
                    
                    ELSE
                        -- the sch or allocation end in the current day
                        pk_date_utils.set_dst_time_check_off;
                        IF NOT add_tab_element(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_type              => l_reg_type_str,
                                               i_id_bed            => l_id_bed,
                                               i_id_patient        => l_id_patient,
                                               i_dt_begin          => l_dt_begin,
                                               i_dt_end            => l_dt_end,
                                               i_begin_hour        => '00:00' ||
                                                                      pk_message.get_message(i_lang, g_msg_hour_indicator),
                                               i_end_hour          => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                       l_dt_end,
                                                                                                       i_prof.institution,
                                                                                                       i_prof.software),
                                               i_icon              => pk_schedule.g_icon_prefix || 'ExtendIcon',
                                               i_order             => 3,
                                               i_id_schedule       => l_schedule,
                                               i_flg_color_session => g_flg_color_session_f,
                                               io_idx              => idx,
                                               io_tab              => l_tab_lv_data,
                                               o_error             => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                        pk_date_utils.set_dst_time_check_on;
                    END IF;
                
                ELSE
                    --begins on the current day
                    pk_date_utils.set_dst_time_check_off;
                    IF NOT add_tab_element(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_type              => l_reg_type_str,
                                      i_id_bed            => l_id_bed,
                                      i_id_patient        => l_id_patient,
                                      i_dt_begin          => l_dt_begin,
                                      i_dt_end            => l_dt_end,
                                      i_begin_hour        => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                              l_dt_begin,
                                                                                              i_prof.institution,
                                                                                              i_prof.software),
                                      i_end_hour          => CASE
                                                                 WHEN (l_dt_end < i_date_tz_local + 1) THEN
                                                                  pk_date_utils.date_char_hour_tsz(i_lang, -- se acabar no mm dia
                                                                                                   l_dt_end,
                                                                                                   i_prof.institution,
                                                                                                   i_prof.software)
                                                                 ELSE
                                                                  '24:00' || pk_message.get_message(i_lang, g_msg_hour_indicator)
                                                             END,
                                      i_icon              => pk_schedule.g_icon_prefix || 'ExtendIcon',
                                      i_order             => 3,
                                      i_id_schedule       => l_schedule,
                                      i_flg_color_session => g_flg_color_session_f,
                                      io_idx              => idx,
                                      io_tab              => l_tab_lv_data,
                                      o_error             => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                    pk_date_utils.set_dst_time_check_on;
                END IF;
            END IF;
        
            l_previous_schedule   := l_schedule;
            l_previous_id_bed     := l_id_bed;
            l_previous_id_patient := l_id_patient;
            l_previous_dt_begin   := l_dt_begin;
            l_previous_dt_end     := l_dt_end;
        
        END LOOP;
    
        g_error := 'CALL  calc_groups_and_slots';
        IF NOT calc_groups_and_slots(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_date_tz_local     => i_date_tz_local,
                                     io_tab_lv_data      => l_tab_lv_data,
                                     i_nr_elems_same_bed => l_count_elems_same_bed,
                                     i_id_bed            => l_id_bed,
                                     io_idx              => idx,
                                     i_has_full_day      => l_has_full_day,
                                     o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_tab_lv_data := l_tab_lv_data;
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
    END calc_occupations_and_groups;

    /**********************************************************************************************
    * This function returns the grid body information in Timetable View format for a week (i_date' s week)
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_location                      Location ID
    * @param i_ward                          Ward ID
    * @param o_header_text                   String with header information
    * @param o_listview_info                 Output cursor with sessions, schedules and slots information
    * @param o_colors                        Output cursor with colors information
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Jose Antunes
    * @version                               2.5
    * @since                                 2009/05/19
    *
    * Updated: return desc_dcs and date timezones correction
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/20
    **********************************************************************************************/
    FUNCTION get_listview_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN VARCHAR2,
        i_location      IN institution.id_institution%TYPE,
        i_ward          IN department.id_department%TYPE,
        o_header_text   OUT VARCHAR2,
        o_listview_info OUT pk_types.cursor_type,
        o_colors        OUT pk_types.cursor_type,
        o_ward_name     OUT VARCHAR2,
        o_blocked_bed   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_location_name VARCHAR2(400);
        l_func_name     VARCHAR2(30) := 'GET_LISTVIEW_INFO';
        l_date_tz       TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_date_tz_local TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        l_timezone VARCHAR2(4000);
    
        l_date_str VARCHAR2(14);
        l_day_str  VARCHAR2(10);
    
        l_allocations      pk_types.cursor_type;
        l_alloc_id_bed     bed.id_bed%TYPE;
        l_alloc_id_patient patient.id_patient%TYPE;
        l_alloc_dt_begin   TIMESTAMP WITH LOCAL TIME ZONE;
        l_alloc_dt_end     TIMESTAMP WITH LOCAL TIME ZONE;
        l_alloc_id         bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_alloc_episode    bmng_allocation_bed.id_episode%TYPE;
        l_id_schedule      schedule.id_schedule%TYPE;
    
        l_rec        t_rec_sch_alloc;
        l_tab_allocs t_tab_sch_alloc := t_tab_sch_alloc();
        idx          NUMBER := 1;
    
        l_occupations      pk_types.cursor_type;
        l_tab_id_schedules table_number := table_number();
    
        l_tab_lv_data t_tab_sch_inp_lv := t_tab_sch_inp_lv();
    
        l_mask sys_message.desc_message%TYPE := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SCH_T766');
    
        l_internal_error EXCEPTION;
        l_schedule_ids    table_number := table_number();
        l_bmng_flg_action bmng_action.flg_action%TYPE;
    BEGIN
    
        g_error := 'CALL PK_DATE_UTILS.GET_TIMEZONE';
        IF NOT
            pk_date_utils.get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR i_date';
        pk_date_utils.set_dst_time_check_off;
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => l_timezone,
                                             o_timestamp => l_date_tz,
                                             o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        g_error    := 'CALL pk_date_utils.get_string_tstz';
        l_day_str  := substr(i_date, 1, 8);
        l_date_str := l_day_str || '000000';
    
        pk_date_utils.set_dst_time_check_off;
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => l_date_str,
                                             i_timezone  => l_timezone,
                                             o_timestamp => l_date_tz_local,
                                             o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        g_error := 'CALL GET_DATE_ALLOCATIONS';
        IF NOT pk_bmng_pbl.get_date_allocations(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_department      => table_number(i_ward),
                                                i_institution     => NULL,
                                                i_dt_begin        => l_date_tz_local,
                                                i_dt_end          => l_date_tz_local + 1,
                                                o_effective_alloc => l_allocations,
                                                o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        LOOP
            g_error := 'LOOP THROUTH l_allocations cursor: idx: ' || idx;
            FETCH l_allocations
                INTO l_alloc_id_bed,
                     l_alloc_id_patient,
                     l_alloc_dt_begin,
                     l_alloc_id,
                     l_alloc_dt_end,
                     l_alloc_episode,
                     l_bmng_flg_action;
            EXIT WHEN l_allocations%NOTFOUND;
        
            -- select id_schedule from sch_allocation        
            BEGIN
                SELECT sa.id_schedule
                  INTO l_id_schedule
                  FROM sch_allocation sa
                 WHERE sa.id_bmng_allocation_bed = l_alloc_id;
            
                l_schedule_ids.extend(1);
                l_schedule_ids(l_schedule_ids.last) := l_id_schedule;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_schedule := NULL;
            END;
        
            IF (l_alloc_dt_end IS NULL OR l_alloc_dt_end < l_alloc_dt_begin OR
               l_alloc_dt_end < pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, g_sysdate_tstz))
            THEN
                l_alloc_dt_end := l_date_tz_local + 1;
            END IF;
        
            IF NOT l_alloc_dt_end < l_alloc_dt_begin
            THEN
                l_rec := t_rec_sch_alloc(l_id_schedule,
                                         l_alloc_id_bed,
                                         l_alloc_id_patient,
                                         l_alloc_dt_begin,
                                         l_alloc_dt_end);
            
                l_tab_allocs.extend(1);
                l_tab_allocs(idx) := l_rec;
                idx := idx + 1;
            END IF;
        END LOOP;
    
        g_error := 'BULK COLLECT id_schedules';
        pk_date_utils.set_dst_time_check_off;
        SELECT s.id_schedule id_schedule
          BULK COLLECT
          INTO l_tab_id_schedules
          FROM schedule s, schedule_bed sb, bed b, sch_group sg, patient p, bed_type bt, room r, room_type rt
         WHERE s.id_schedule = sb.id_schedule
           AND sb.id_bed = b.id_bed
           AND s.id_schedule = sg.id_schedule
           AND p.id_patient = sg.id_patient
           AND bt.id_bed_type(+) = b.id_bed_type
           AND b.id_room = r.id_room
           AND r.id_department = i_ward
           AND r.id_room_type = rt.id_room_type(+)
           AND pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, s.dt_begin_tstz) <
               pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, l_date_tz_local + 1)
           AND pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, s.dt_end_tstz) >
               pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, l_date_tz_local)
              
           AND s.id_sch_event = g_inp_sch_event
           AND s.flg_status <> pk_schedule.g_status_canceled;
    
        g_error := 'OPEN l_occupations cursor';
        OPEN l_occupations FOR
            SELECT *
              FROM (SELECT 'ALLOCATION' AS reg_type_str, t.*
                      FROM TABLE(l_tab_allocs) t
                    UNION ALL
                    SELECT 'SCHEDULE' AS reg_type_str,
                           s.id_schedule,
                           sb.id_bed,
                           sg.id_patient,
                           s.dt_begin_tstz AS dt_begin,
                           s.dt_end_tstz AS dt_end
                      FROM TABLE(l_tab_id_schedules) ts
                      JOIN schedule s
                        ON ts.column_value = s.id_schedule
                      JOIN schedule_bed sb
                        ON s.id_schedule = sb.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = s.id_schedule
                     WHERE NOT EXISTS (SELECT 1
                              FROM TABLE(l_schedule_ids) tb
                             WHERE tb.column_value = s.id_schedule))
             ORDER BY id_bed, dt_begin, reg_type_str;
    
        g_error := 'CALL calc_occupations_and_groups';
        IF NOT calc_occupations_and_groups(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_occupations   => l_occupations,
                                           i_date_tz_local => l_date_tz_local,
                                           o_tab_lv_data   => l_tab_lv_data,
                                           o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_listview_info FOR
            SELECT 1 order_field,
                   'AVAIL' reg_type_str,
                   pk_schedule.g_icon_prefix || 'FreeBedIcon' icon_reg_type,
                   NULL id_schedule,
                   pk_date_utils.date_send_tsz(i_lang, l_date_tz_local, i_prof) dt_begin,
                   NULL dt_end,
                   '00:00' || pk_message.get_message(i_lang, g_msg_hour_indicator) begin_hour,
                   '24:00' || pk_message.get_message(i_lang, g_msg_hour_indicator) end_hour,
                   NULL end_date,
                   NULL id_room,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_type,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                   b.id_bed,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_type,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_type_edit,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name_edit,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_type_edit,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed_edit,
                   --pk_schedule.string_dep_clin_serv(i_lang, bdcs.id_dep_clin_serv) desc_dcs,
                   pk_bmng.get_bed_dep_clin_serv(i_lang, i_prof, b.id_bed) desc_dcs,
                   NULL indication,
                   pk_schedule_inp.get_bed_availability(i_lang, i_prof, l_date_tz_local, b.id_bed, NULL) availability,
                   NULL patient_name,
                   NULL pat_ndo,
                   NULL pat_nd_icon,
                   NULL photo,
                   NULL gender,
                   NULL pat_age,
                   NULL ind_admission,
                   NULL date_discharge,
                   'S' flg_color_session,
                   NULL id_waiting_list,
                   g_no flg_group,
                   NULL flg_notification,
                   NULL notif_icon_status,
                   NULL flg_temporary,
                   NULL flg_status,
                   NULL icon_sch_status,
                   NULL AS id_patient,
                   '' AS flg_registered
              FROM sch_bed_slot sbs, bed b, bed_type bt, room r, room_type rt
             WHERE b.id_bed = sbs.id_bed
               AND bt.id_bed_type(+) = b.id_bed_type
               AND b.id_room = r.id_room
               AND r.id_department = i_ward
               AND r.id_room_type = rt.id_room_type(+)
               AND trunc(sbs.dt_begin, 'DD') <= trunc(l_date_tz, 'DD')
               AND trunc(sbs.dt_end, 'DD') >= trunc(l_date_tz + 1, 'DD')
               AND NOT EXISTS (SELECT 1
                      FROM TABLE(l_tab_lv_data) t
                     WHERE t.id_bed = b.id_bed)
               AND b.flg_type <> pk_bmng_constant.g_bmng_bed_flg_type_t
            UNION ALL
            
            SELECT tab.position order_field,
                   tab.type reg_type_str,
                   tab.icon AS icon_reg_type,
                   tab.elem_id id_schedule,
                   pk_date_utils.date_send_tsz(i_lang, tab.dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, tab.dt_end, i_prof) dt_end,
                   tab.begin_hour AS begin_hour,
                   tab.end_hour AS end_hour,
                   CASE
                       WHEN tab.dt_end < tab.dt_begin THEN
                        NULL
                       ELSE
                        pk_date_utils.to_char_insttimezone(i_lang, i_prof, tab.dt_end, l_mask)
                   END end_date,
                   b.id_room,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_type,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                   tab.id_bed AS id_bed,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_type,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed,
                   nvl(rt.desc_room_type, pk_translation.get_translation(i_lang, rt.code_room_type)) room_type_edit,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name_edit,
                   nvl(bt.desc_bed_type, pk_translation.get_translation(i_lang, bt.code_bed_type)) bed_type_edit,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed_edit,
                   CASE
                       WHEN tab.type NOT IN (g_lv_type_group, g_lv_type_allocation) THEN
                        get_clinical_service_desc(i_lang, i_prof, tab.id_bed, s.id_dcs_requested)
                   END desc_dcs,
                   CASE
                       WHEN sb.id_waiting_list IS NOT NULL THEN
                        pk_admission_request.get_adm_indication_desc(i_lang, i_prof, sb.id_waiting_list)
                   END indication,
                   CASE
                       WHEN tab.type != g_lv_type_allocation THEN
                        decode(tab.icon,
                               pk_schedule.g_icon_prefix || 'ExtendIcon',
                               NULL,
                               pk_schedule_inp.get_bed_availability(i_lang, i_prof, l_date_tz_local, b.id_bed, tab.type))
                   END AS availability,
                   --pk_patient.get_patient_name(i_lang, tab.id_patient) patient_name,
                   pk_patient.get_pat_name(i_lang, i_prof, tab.id_patient, NULL) patient_name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, tab.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, tab.id_patient) pat_nd_icon,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, tab.id_patient, s.id_episode, s.id_schedule) photo,
                   pk_patient.get_gender(i_lang, p.gender) AS gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   NULL ind_admission,
                   NULL date_discharge,
                   tab.flg_color_session flg_color_session,
                   sb.id_waiting_list AS id_waiting_list,
                   decode(tab.icon, pk_schedule.g_icon_prefix || 'DetailInternmentIcon', g_no, g_yes) flg_group,
                   s.flg_notification AS flg_notification,
                   CASE
                       WHEN flg_notification IS NOT NULL THEN
                        pk_schedule.g_icon_prefix ||
                        pk_sysdomain.get_img(i_lang, pk_schedule.g_sched_flg_notif_status, flg_notification)
                       ELSE
                        NULL
                   END notif_icon_status,
                   sb.flg_temporary,
                   s.flg_status,
                   get_status_icon(i_lang, i_prof, tab.type, tab.elem_id) AS icon_sch_status,
                   p.id_patient AS id_patient,
                   pk_inp_episode.is_epis_registered(i_lang, s.id_episode) AS flg_registered
              FROM TABLE(l_tab_lv_data) tab,
                   bed b,
                   bed_type bt,
                   room r,
                   room_type rt,
                   patient p,
                   schedule s,
                   schedule_bed sb
             WHERE tab.id_bed = b.id_bed
               AND b.id_room = r.id_room
               AND r.id_room_type = rt.id_room_type(+)
               AND bt.id_bed_type(+) = b.id_bed_type
               AND p.id_patient(+) = tab.id_patient
               AND tab.elem_id = s.id_schedule(+)
               AND sb.id_schedule(+) = s.id_schedule
               AND b.flg_type = 'P'
            
             ORDER BY room_name_edit, desc_bed_edit, begin_hour, order_field, end_hour;
        pk_date_utils.set_dst_time_check_on;
    
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
    
        g_error := 'GET LOCATION NAME';
        SELECT pk_translation.get_translation(i_lang, i.code_institution)
          INTO l_location_name
          FROM institution i
         WHERE i.id_institution = i_location;
    
        g_error := 'GET WARD NAME';
        SELECT pk_translation.get_translation(i_lang, d.code_department)
          INTO o_ward_name
          FROM department d
         WHERE d.id_department = i_ward;
    
        g_error := 'CALL GET_TIMETABLE_HEADER';
        IF NOT pk_schedule_inp.get_grid_header(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_date          => l_date_tz_local,
                                               i_flg_viewtype  => g_flg_list_view,
                                               i_location_name => l_location_name,
                                               i_ward_name     => o_ward_name,
                                               o_header_text   => o_header_text,
                                               o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        --get blocked beds
        g_error := 'CALL pk_bmng_pbl.get_blocked_beds';
        IF NOT pk_bmng_pbl.get_blocked_beds(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_id_department => i_ward,
                                            i_start_date    => trunc(l_date_tz),
                                            i_end_date      => trunc(l_date_tz) + 1,
                                            o_beds          => o_blocked_bed,
                                            o_error         => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_listview_info);
            pk_types.open_my_cursor(o_colors);
            pk_types.open_my_cursor(o_blocked_bed);
        
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
    * Get the availability of a bed
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_id_bed                        Bed ID
    *
    * @return                                Success / fail
    *
    * @author                                Jose Antunes
    * @version                               2.5
    * @since                                 2009/05/25
    *
    * UPDATED: ALERT-41802
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/09/03
    **********************************************************************************************/
    FUNCTION get_bed_availability
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bed IN bed.id_bed%TYPE,
        i_type   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name    VARCHAR2(32) := 'GET_BED_AVAILABILITY';
        l_duration     VARCHAR2(32);
        l_id_bed       schedule_bed.id_bed%TYPE;
        l_id_schedule  schedule.id_schedule%TYPE;
        l_dt_begin     schedule.dt_begin_tstz%TYPE;
        l_dt_end       schedule.dt_end_tstz%TYPE;
        l_exists       NUMBER(1);
        l_elapsed_time NUMBER;
        l_elapsed_desc VARCHAR2(4000);
        l_error        t_error_out;
    
    BEGIN
    
        IF (i_type = g_lv_type_group)
        THEN
            -- ver o nr de horas livres durante o dia corrente
            SELECT SUM(pk_date_utils.get_timestamp_diff(CASE
                                                             WHEN s.dt_end_tstz > i_date + 1 THEN
                                                              i_date + 1
                                                             ELSE
                                                              s.dt_end_tstz
                                                         END,
                                                         CASE
                                                             WHEN s.dt_begin_tstz < i_date THEN
                                                              i_date
                                                             ELSE
                                                              s.dt_begin_tstz
                                                         END))
              INTO l_elapsed_time
              FROM schedule s, schedule_bed sb
             WHERE s.id_schedule = sb.id_schedule
               AND sb.id_bed = i_id_bed
               AND s.flg_status <> pk_schedule.g_status_canceled
               AND s.dt_begin_tstz < i_date + 1
               AND s.dt_end_tstz > i_date;
        
            IF NOT pk_date_utils.get_elapsed_time_desc(i_lang    => i_lang,
                                                       i_elapsed => 1 - l_elapsed_time,
                                                       o_desc    => l_elapsed_desc,
                                                       o_error   => l_error)
            THEN
                RETURN NULL;
            END IF;
        
            IF (l_elapsed_desc IS NULL)
            THEN
                RETURN '';
            ELSE
                RETURN l_elapsed_desc || pk_message.get_message(i_lang, g_msg_hour_indicator);
            END IF;
        
        END IF;
    
        -- get schedule data
        g_error := 'GET SCHEDULE DURING NEXT NIGHT';
        SELECT COUNT(1)
          INTO l_exists
          FROM schedule s
         INNER JOIN schedule_bed sb
            ON sb.id_schedule = s.id_schedule
         WHERE trunc(s.dt_begin_tstz, 'DD') < trunc(i_date + INTERVAL '1' DAY, 'DD')
           AND trunc(s.dt_end_tstz, 'DD') >= trunc(i_date + INTERVAL '1' DAY, 'DD')
           AND sb.id_bed = i_id_bed
           AND s.flg_status <> pk_schedule.g_status_canceled;
    
        -- If there is a schedule during the night, bed is occupied
        IF l_exists > 0
        THEN
            RETURN pk_message.get_message(i_lang, 'SCH_T600');
        END IF;
    
        BEGIN
            g_error := 'GET NEXT SCHEDULE';
            SELECT s.id_schedule, s.dt_begin_tstz, s.dt_end_tstz
              INTO l_id_schedule, l_dt_begin, l_dt_end
              FROM schedule s
             INNER JOIN schedule_bed sb
                ON sb.id_schedule = s.id_schedule
             WHERE trunc(s.dt_begin_tstz, 'DD') >= trunc(i_date + INTERVAL '1' DAY, 'DD')
               AND sb.id_bed = i_id_bed
               AND trunc(s.dt_begin_tstz + INTERVAL '1' DAY, 'DD') >= trunc(i_date + INTERVAL '1' DAY, 'DD')
               AND s.flg_status <> pk_schedule.g_status_canceled
               AND rownum = 1
             ORDER BY dt_begin_tstz;
        
        EXCEPTION
            WHEN no_data_found THEN
                -- If there is no schedule after midnight, bed is free
                RETURN pk_message.get_message(i_lang, 'SCH_T601');
        END;
    
        l_duration := pk_date_utils.get_elapsed_tsz(i_lang, l_dt_begin, i_date);
    
        RETURN l_duration;
    
    END get_bed_availability;

    /**********************************************************************************************
    * Get the icon for a schedule in list view
    *
    * @param i_date                          Input date
    * @param i_schedule                      Schedule ID
    *
    * @return                                Success / fail
    *
    * @author                                Jose Antunes
    * @version                               2.5
    * @since                                 2009/05/26
    **********************************************************************************************/
    FUNCTION get_schedule_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name   VARCHAR2(32) := 'GET_SCHEDULE_ICON';
        l_date        TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_id_bed      schedule_bed.id_bed%TYPE;
        l_id_schedule schedule.id_schedule%TYPE;
        l_dt_begin    schedule.dt_begin_tstz%TYPE;
        l_dt_end      schedule.dt_end_tstz%TYPE;
        l_exists      NUMBER(1);
    
    BEGIN
    
        g_error := 'GET SCHEDULE BEGIN AND END DATE';
        SELECT dt_begin_tstz, dt_end_tstz
          INTO l_dt_begin, l_dt_end
          FROM schedule s
         WHERE s.id_schedule = i_schedule;
    
        IF trunc(l_dt_begin, 'DD') < trunc(i_date, 'DD')
           AND trunc(l_dt_end, 'DD') > trunc(i_date, 'DD')
        THEN
            RETURN pk_schedule.g_icon_prefix || 'DetailInternmentIcon';
        ELSE
            RETURN pk_schedule.g_icon_prefix || 'ExtendIcon';
        END IF;
    
    END get_schedule_icon;

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
    * @since                                 2009/05/19
    **********************************************************************************************/
    FUNCTION get_sch_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_SCH_CLIPBOARD';
        l_id_wl        table_number;
        l_args         table_varchar;
        l_string_id_wl VARCHAR2(4000);
    BEGIN
    
        g_error := 'GET ID_WAITING_LIST';
        SELECT sb.id_waiting_list
          BULK COLLECT
          INTO l_id_wl
          FROM sch_clipboard sc, schedule s, schedule_bed sb
         WHERE sc.id_schedule = s.id_schedule
           AND s.id_schedule = sb.id_schedule
           AND s.id_sch_event = g_inp_sch_event
           AND sc.id_prof_created = i_prof.id
           AND s.flg_status <> pk_schedule.g_status_canceled;
    
        g_error := 'CREATE LIST OF ID_WAITING_LIST';
        IF (l_id_wl.count > 0)
        THEN
            FOR i IN 1 .. l_id_wl.count
            LOOP
                IF l_string_id_wl IS NULL
                THEN
                    l_string_id_wl := l_id_wl(1);
                ELSE
                    l_string_id_wl := l_string_id_wl || ',' || l_id_wl(i);
                END IF;
            END LOOP;
        
            g_error := 'CREATE L_ARGS';
            l_args  := table_varchar('',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     '',
                                     l_string_id_wl,
                                     g_no,
                                     '',
                                     '');
        
            g_error := 'CALL PK_WTL_PBL_CORE.GET_WTLIST_SEARCH_INPATIENT';
            IF NOT pk_wtl_pbl_core.get_wtlist_search_inpatient(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_args_inp => l_args,
                                                               o_wtlist   => o_schedules,
                                                               o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_schedules);
        END IF;
    
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
    * This function determines the grid header text
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date    
    * @param i_flg_viewtype                  View: O-Overview; L-List view
    * @param i_location_name                 Location
    * @param i_ward_name                     Ward 
    * @param o_header_text                   Grid header text with HTML Tags for bold text
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5
    * @since                                 2009/05/18
    **********************************************************************************************/
    FUNCTION get_grid_header
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_viewtype  IN VARCHAR2,
        i_location_name IN VARCHAR2,
        i_ward_name     IN VARCHAR2,
        o_header_text   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_GRID_HEADER';
        l_date      VARCHAR2(4001);
        l_msg_inp   sys_message.desc_message%TYPE;
        l_desc_view sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'GET MESSAGE SCH_T549';
        -- Inpatient label
        l_msg_inp := pk_message.get_message(i_lang, 'SCH_T549');
    
        g_error := 'GET VIEW MESSAGE';
        -- OverView
        IF i_flg_viewtype = g_flg_overview
        THEN
            l_desc_view := pk_message.get_message(i_lang, 'SCH_T528');
        ELSIF i_flg_viewtype = g_flg_list_view
        THEN
            --List View
            l_desc_view := pk_message.get_message(i_lang, 'SCH_T550');
        END IF;
    
        g_error := 'DAILY VIEW';
        g_error := 'CALL pk_schedule.get_dmy_string_date';
        IF NOT pk_schedule.get_dmy_string_date(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_date           => pk_date_utils.date_send_tsz(i_lang, i_date, i_prof),
                                               o_described_date => l_date,
                                               o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_header_text := ' <B>' || l_date || ' - ' || l_msg_inp || '-</B> ';
    
        IF i_flg_viewtype = g_flg_list_view
        THEN
            o_header_text := o_header_text || i_location_name || ', ' || i_ward_name;
        END IF;
    
        o_header_text := o_header_text || ' (' || l_desc_view || ')';
    
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
    * This function returns the grid top location description.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array    
    * @param i_institution                   Institution ID
    * @param o_locations                     Output cursor with locations info
    * @param o_header_text                   Text to the grid header    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5
    * @since                                 2009/05/18
    **********************************************************************************************/
    FUNCTION get_timetable_locations
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_locations_ids IN table_number,
        o_locations     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_TIMETABLE_HEADER';
    BEGIN
    
        IF i_locations_ids IS NOT NULL
           AND i_locations_ids.exists(1)
           AND TRIM(i_locations_ids(1)) IS NOT NULL
        THEN
            g_error := 'OPEN o_locations cursor';
            OPEN o_locations FOR
                SELECT inst.id_institution,
                       pk_translation.get_translation(i_lang, inst.code_institution) institution_desc
                
                  FROM institution inst
                 WHERE inst.id_institution IN (SELECT column_value
                                                 FROM TABLE(i_locations_ids));
        ELSE
        
            g_error := 'CALL get_locations';
            IF NOT get_locations(i_lang => i_lang, i_prof => i_prof, o_locations => o_locations, o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        /*g_error := 'CALL GET_GRID_HEADER';
        IF NOT get_grid_header(i_lang, i_prof, i_date, g_flg_overview, NULL, NULL, o_header_text, o_error)
        THEN
            RETURN FALSE;
        END IF;*/
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_locations);
        
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
        
    END get_timetable_locations;

    /**********************************************************************************************
    * This function returns the list of the dep_clin_serv with beds to the indicated locations
    * It is only included the dep_clin_servs of wards which beds have the same specialty
    *
    * @param i_lang                          Language ID    
    * @param i_locations                     Input date    
    * @param o_tab_dep_clin_servs            Dep_clin_serv IDs    
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5
    * @since                                 2009/05/19
    **********************************************************************************************/
    FUNCTION get_room_dcs_list
    (
        i_lang               IN language.id_language%TYPE,
        i_locations          IN table_number,
        o_tab_dep_clin_servs OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ROOM_DEP_CLIN_SERV_LIST';
    BEGIN
        g_error := 'OPEN o_tab_dep_clin_servs';
        SELECT dcs
          BULK COLLECT
          INTO o_tab_dep_clin_servs
          FROM (SELECT (bdcs.id_dep_clin_serv) dcs, d.id_department
                  FROM department d
                  JOIN room r
                    ON d.id_department = r.id_department
                  JOIN bed b
                    ON b.id_room = r.id_room
                  JOIN bed_dep_clin_serv bdcs
                    ON bdcs.id_bed = b.id_bed
                 WHERE ((SELECT COUNT(DISTINCT bdcs2.id_dep_clin_serv)
                           FROM bed_dep_clin_serv bdcs2
                           JOIN bed b2
                             ON b2.id_bed = bdcs2.id_bed
                           JOIN room r2
                             ON b2.id_room = r2.id_room
                           JOIN department d2
                             ON r2.id_department = d2.id_department
                          WHERE b2.id_room = r2.id_room
                            AND r2.id_department = d.id_department
                            AND instr(d2.flg_type, 'I') > 0
                            AND d2.flg_available = g_yes
                            AND b.flg_available = g_yes
                            AND r.flg_available = g_yes
                            AND d2.id_institution IN (SELECT column_value
                                                        FROM TABLE(i_locations))
                            AND bdcs2.flg_available = g_yes) = 1));
    
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
    END get_room_dcs_list;

    /**********************************************************************************************
    * This function returns a flag indicating if the ward has an associated dep_clin_serv or not, 
    * or if it has 2 or more dep_clin_servs 
    *
    * @param i_lang                     Language ID    
    * @param i_id_institution           Institution ID    
    * @param i_id_department            Department ID        
    *
    * @return                           'W' - without dep_clin_serv;
    *                                   'M' - 2 or more dep_clin_servs
    *                                   dep_clin_serv ID
    *
    * @author                           Sofia Mendes
    * @version                          2.5
    * @since                            2009/05/19
    **********************************************************************************************/
    FUNCTION get_room_dep_clin_serv
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_department  IN department.id_department%TYPE,
        i_id_room        IN room.id_room%TYPE
    ) RETURN VARCHAR2 IS
        l_tab_dep_clin_servs table_number;
    
    BEGIN
        g_error := 'SELECT';
        SELECT DISTINCT (bdcs.id_dep_clin_serv)
          BULK COLLECT
          INTO l_tab_dep_clin_servs
          FROM department d
          JOIN room r
            ON d.id_department = r.id_department
          JOIN bed b
            ON r.id_room = b.id_room
          JOIN bed_dep_clin_serv bdcs
            ON bdcs.id_bed = b.id_bed
         WHERE d.id_institution = i_id_institution
           AND d.id_department = i_id_department
           AND bdcs.flg_available = g_yes
           AND (r.id_room = i_id_room OR i_id_room IS NULL);
    
        IF (l_tab_dep_clin_servs.count = 0)
        THEN
            RETURN g_no_specialty;
        ELSIF (l_tab_dep_clin_servs.count = 1)
        THEN
            RETURN l_tab_dep_clin_servs(1);
        ELSE
            RETURN g_multi_specs;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_room_dep_clin_serv;

    /********************************************************************************************
    * Gets the list of departments for a list of institutions
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_institutions               institution IDs
    * @param o_department                 department list
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Sofia Mendes
    * @version                            2.5.0.5
    * @since                              21-07-2009
    **********************************************************************************************/
    FUNCTION get_departments_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institutions IN table_number,
        o_departments  OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_DEPARTMENTS_LIST';
    BEGIN
        g_error := 'GET CURSOR';
        SELECT id_department
          BULK COLLECT
          INTO o_departments
          FROM department d
         WHERE id_institution IN (SELECT column_value
                                    FROM TABLE(i_institutions))
           AND EXISTS (SELECT r.id_department
                  FROM room r
                 WHERE r.id_department = d.id_department
                   AND r.flg_transp = pk_alert_constant.g_available
                   AND r.flg_available = pk_alert_constant.g_available)
           AND instr(d.flg_type, 'I') > 0
           AND d.flg_available = pk_alert_constant.g_available;
        --ORDER BY rank, department;
    
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
    END get_departments_list;

    /**********************************************************************************************
    * This function returns the data to fill the Overview screen.
    * The blocked beds is not being stored in the sch_room_stats table because this info is already being maintained
    * in a easy access table. The total beds (total beds without blocked beds + nr of blocked beds)
    * is being calculated by the flash layer
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date   
    * @param i_locations_ids                 Locations ID to be considered (Null=all locations) 
    * @param o_header_text                   Header text 
    * @param o_locations                     Output cursor with locations data
    * @param o_timetable_data                Output cursor with data to the timetable
    * @param o_colors                        Output cursor with colors info
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/20
    **********************************************************************************************/
    FUNCTION get_timetable_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN VARCHAR2,
        i_locations_ids  IN table_number,
        o_header_text    OUT VARCHAR2,
        o_timetable_data OUT pk_types.cursor_type,
        o_colors         OUT pk_types.cursor_type,
        o_depart_info    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(30) := 'GET_TIMETABLE_DATA';
        l_date                  TIMESTAMP(6) WITH TIME ZONE;
        l_trunced_date          TIMESTAMP(6) WITH TIME ZONE;
        l_tab_locations_ids     table_number;
        l_tab_locations_names   table_varchar;
        l_locations             pk_types.cursor_type;
        l_tab_dep_clin_serv_ids table_number := table_number();
        l_count_srs             NUMBER;
        l_dt_day                NUMBER;
        l_timezone              VARCHAR2(4000);
        l_departments           table_number;
        l_nchs_in_use           table_number := table_number();
        l_department            department.id_department%TYPE;
        l_blocked_bed           NUMBER;
        l_total_nch             NUMBER;
        l_depart_info           pk_types.cursor_type;
        l_deps                  table_number := table_number();
        l_blocked_beds          table_number := table_number();
        l_total_nchs            table_number := table_number();
        ind                     NUMBER := 1;
        l_nch_avail             NUMBER;
    
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL PK_DATE_UTILS.GET_TIMEZONE';
        IF NOT pk_date_utils.get_timezone(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_timezone => NULL,
                                          o_timezone => l_timezone,
                                          o_error    => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CONVERT INPUT DATE FROM STRING TO TSTZ FORMAT';
    
        pk_date_utils.set_dst_time_check_off;
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => l_timezone,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        g_error := 'CALL GET_GRID_HEADER';
        IF NOT get_grid_header(i_lang, i_prof, l_date, g_flg_overview, NULL, NULL, o_header_text, o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL PK_DATE_UTILS.TRUNC_INSTTIMEZONE';
        pk_date_utils.set_dst_time_check_off;
        l_trunced_date := pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => l_date);
        pk_date_utils.set_dst_time_check_on;
    
        l_dt_day := to_number(to_char(l_trunced_date, 'J'));
    
        --initialize sch_room_stats
        g_error := 'VERIFY IF IT IS TO INICIALIZE';
    
        SELECT COUNT(r.id_room)
          INTO l_count_srs
          FROM institution samehc
          JOIN department d
            ON (d.id_institution = samehc.id_institution)
          JOIN room r
            ON (r.id_department = d.id_department)
          JOIN bed b
            ON (b.id_room = r.id_room)
          JOIN institution i
            ON (i.id_institution = i_prof.institution)
         WHERE (samehc.id_parent = i.id_parent OR samehc.id_institution = i.id_institution)
           AND d.flg_available = pk_alert_constant.g_yes
           AND r.flg_available = pk_alert_constant.g_yes
           AND b.flg_available = pk_alert_constant.g_yes
           AND instr(d.flg_type, 'I') > 0
           AND r.id_room NOT IN (SELECT srs.id_room
                                   FROM sch_room_stats srs
                                  WHERE srs.dt_day = l_dt_day);
    
        IF (l_count_srs != 0)
        THEN
            g_error := 'CALL INIT_SCH_ROOM_STATS';
            IF NOT init_sch_room_stats(i_lang, i_prof, l_date, o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        END IF;
    
        IF i_locations_ids IS NOT NULL
           AND i_locations_ids.exists(1)
           AND TRIM(i_locations_ids(1)) IS NOT NULL
        THEN
            l_tab_locations_ids := i_locations_ids;
        
        ELSE
            g_error := 'CALL get_locations';
            IF NOT get_locations(i_lang => i_lang, i_prof => i_prof, o_locations => l_locations, o_error => o_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            g_error := 'BULK COLLECT';
            FETCH l_locations BULK COLLECT
                INTO l_tab_locations_ids, l_tab_locations_names;
            CLOSE l_locations;
        
        END IF;
    
        g_error := 'OPEN CURSOR O_TIMETABLE_DATA';
        OPEN o_timetable_data FOR
            SELECT d.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) location_name,
                   d.id_department,
                   to_char(pk_date_utils.add_to_ltstz(l_trunced_date,
                                                      nvl(sidt.admission_time, g_default_begin_day),
                                                      'MINUTE'),
                           'HH24:MI') AS discharges_hour,
                   pk_translation.get_translation(i_lang, d.code_department) AS ward_name,
                   SUM(total_beds) AS total_beds,
                   SUM(total_occupied) AS total_occupied,
                   SUM(total_free) AS total_free,
                   SUM(total_free_with_dcs) AS total_free_with_dcs,
                   get_room_dep_clin_serv(i_lang, d.id_institution, d.id_department, NULL) flg_speciality
              FROM sch_room_stats srs
              JOIN department d
                ON srs.id_department = d.id_department
              JOIN institution i
                ON i.id_institution = d.id_institution
              LEFT JOIN sch_inp_dep_time sidt
                ON sidt.id_department = d.id_department
             WHERE i.id_institution IN (SELECT column_value
                                          FROM TABLE(l_tab_locations_ids))
               AND srs.dt_day = l_dt_day
             GROUP BY d.id_institution, i.code_institution, d.id_department, d.code_department, sidt.admission_time
             ORDER BY d.id_institution, ward_name;
    
        g_error := 'CALL GET_DEPARTMENTS_LIST';
        IF NOT get_departments_list(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_institutions => l_tab_locations_ids,
                                    o_departments  => l_departments,
                                    o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL pk_bmng_pbl.get_total_department_info';
        IF NOT pk_bmng_pbl.get_total_department_info(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_department  => l_departments,
                                                     i_institution => NULL,
                                                     i_dt_request  => l_trunced_date,
                                                     o_dep_info    => l_depart_info,
                                                     o_error       => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        LOOP
            g_error := 'LOOP THROUTH l_pat_info cursor: ' || ind;
            FETCH l_depart_info
                INTO l_department, l_blocked_bed, l_total_nch, l_nch_avail;
            EXIT WHEN l_depart_info%NOTFOUND;
        
            l_nchs_in_use.extend(1);
            g_error := 'CALL calc_nchs_in_use ' || ind;
        
            IF (l_nch_avail IS NOT NULL)
            THEN
            
                IF NOT calc_nchs_in_use(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_id_department => l_department,
                                        i_start_date    => l_trunced_date,
                                        i_end_date      => l_trunced_date + 1,
                                        i_flg_between   => pk_alert_constant.g_no,
                                        i_dep_nch       => l_total_nch,
                                        o_nchs          => l_nchs_in_use(ind),
                                        o_error         => o_error)
                THEN
                    RAISE l_internal_error;
                END IF;
            END IF;
        
            l_deps.extend(1);
            l_blocked_beds.extend(1);
            l_total_nchs.extend(1);
        
            l_deps(ind) := l_department;
            l_blocked_beds(ind) := l_blocked_bed;
            l_total_nchs(ind) := l_nch_avail;
            ind := ind + 1;
        END LOOP;
        CLOSE l_depart_info;
    
        OPEN o_depart_info FOR
            SELECT t_deps.department,
                   t_blocked.blocked_beds AS beds_blocked,
                   CASE
                        WHEN t_total_nchs.total_nchs IS NOT NULL THEN
                         t_total_nchs.total_nchs || pk_message.get_message(i_lang, g_msg_hour_indicator)
                        ELSE
                         NULL
                    END AS nch_total,
                   CASE
                        WHEN t_total_nchs.total_nchs IS NOT NULL THEN
                        /*(t_total_nchs.total_nchs -*/
                         t_nchs_use.nchs_in_use /*)*/
                         || pk_message.get_message(i_lang, g_msg_hour_indicator)
                        ELSE
                         NULL
                    END AS nch_available
              FROM (SELECT rownum AS index_dep, column_value AS department
                      FROM TABLE(l_deps)) t_deps,
                   (SELECT rownum AS index_blocked, column_value AS blocked_beds
                      FROM TABLE(l_blocked_beds)) t_blocked,
                   (SELECT rownum AS index_total_nchs, column_value AS total_nchs
                      FROM TABLE(l_total_nchs)) t_total_nchs,
                   (SELECT rownum AS index_nchs_in_use, column_value AS nchs_in_use
                      FROM TABLE(l_nchs_in_use)) t_nchs_use
             WHERE t_deps.index_dep = t_blocked.index_blocked
               AND t_blocked.index_blocked = t_total_nchs.index_total_nchs
               AND t_total_nchs.index_total_nchs = t_nchs_use.index_nchs_in_use;
    
        g_error := 'CALL PRIVATE FUNCTION: GET_ROOM_DCS_LIST';
        IF NOT (get_room_dcs_list(i_lang, l_tab_locations_ids, l_tab_dep_clin_serv_ids, o_error))
        THEN
            RAISE l_internal_error;
        END IF;
    
        l_tab_locations_ids := l_tab_locations_ids MULTISET UNION DISTINCT table_number(0);
    
        g_error := 'OPEN CURSOR O_COLORS';
        OPEN o_colors FOR
            SELECT color_name, g_color_prefix || color_hex color_hex
              FROM sch_color sc
             WHERE (sc.color_name = 'FREE_BEDS_WITHOUT_SPEC' OR sc.color_name = 'BLOCKED_BEDS' OR
                   sc.color_name = 'OCCUPIED_BEDS' OR sc.color_name = 'TOTAL_BEDS' OR sc.color_name = g_multi_specs OR
                   sc.color_name = g_no_specialty)
               AND flg_type = 'N'
            UNION ALL
            SELECT to_char(sc.id_dep_clin_serv) AS color_name, g_color_prefix || sc.color_hex AS hex_color
              FROM sch_color sc
             WHERE id_institution IN (SELECT column_value
                                        FROM TABLE(l_tab_locations_ids))
               AND flg_type = 'D'
               AND sc.id_dep_clin_serv IN (SELECT *
                                             FROM TABLE(l_tab_dep_clin_serv_ids));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_header_text := NULL;
            pk_types.open_my_cursor(o_timetable_data);
            pk_types.open_my_cursor(l_locations);
            pk_types.open_my_cursor(o_colors);
            pk_types.open_my_cursor(o_depart_info);
            pk_types.open_my_cursor(l_depart_info);
        
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
    END get_timetable_data;

    /**********************************************************************************************
    * This function inserts the initial data for a day in the sch_room_stats table.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date   
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/20
    **********************************************************************************************/
    FUNCTION init_sch_room_stats
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN TIMESTAMP WITH TIME ZONE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'INIT_SCH_ROOM_STATS';
    BEGIN
        MERGE INTO sch_room_stats srs
        USING (SELECT id_department,
                      id_room,
                      dt_day,
                      total_blocked + total_occupied + total_free + total_free_with_dcs AS total_beds,
                      total_blocked,
                      total_occupied,
                      total_free,
                      total_free_with_dcs
                 FROM (SELECT d.id_department,
                              r.id_room,
                              to_number(to_char(i_date, 'J')) AS dt_day,
                              0 AS total_blocked,
                              0 AS total_occupied,
                              COUNT(CASE
                                         WHEN b.id_bed IN (SELECT bdcs.id_bed
                                                             FROM bed_dep_clin_serv bdcs
                                                            WHERE bdcs.flg_available = g_yes) THEN
                                          NULL
                                         ELSE
                                          1
                                     END) AS total_free,
                              COUNT(CASE
                                         WHEN b.id_bed IN (SELECT bdcs.id_bed
                                                             FROM bed_dep_clin_serv bdcs
                                                            WHERE bdcs.flg_available = g_yes) THEN
                                          1
                                         ELSE
                                          NULL
                                     END) AS total_free_with_dcs
                         FROM institution samehc
                         JOIN department d
                           ON (d.id_institution = samehc.id_institution)
                         JOIN room r
                           ON (r.id_department = d.id_department)
                         JOIN bed b
                           ON (b.id_room = r.id_room)
                         JOIN institution i
                           ON (i.id_institution = i_prof.institution)
                        WHERE (samehc.id_parent = i.id_parent OR samehc.id_institution = i.id_institution)
                          AND d.flg_available = pk_alert_constant.g_yes
                          AND r.flg_available = pk_alert_constant.g_yes
                          AND b.flg_available = pk_alert_constant.g_yes
                          AND b.flg_type <> pk_bmng_constant.g_bmng_bed_flg_type_t
                          AND instr(d.flg_type, 'I') > 0
                        GROUP BY d.id_institution, d.id_department, r.id_room)) t
        ON (srs.id_department = t.id_department AND srs.id_room = t.id_room AND srs.dt_day = t.dt_day)
        WHEN NOT MATCHED THEN
            INSERT
                (id_department,
                 id_room,
                 dt_day,
                 total_beds,
                 total_blocked,
                 total_occupied,
                 total_free,
                 total_free_with_dcs)
            VALUES
                (t.id_department,
                 t.id_room,
                 t.dt_day,
                 t.total_beds,
                 t.total_blocked,
                 t.total_occupied,
                 t.total_free,
                 t.total_free_with_dcs)
        WHEN MATCHED THEN
            UPDATE
               SET srs.total_beds          = t.total_beds,
                   srs.total_blocked       = t.total_blocked,
                   srs.total_occupied      = t.total_occupied,
                   srs.total_free          = t.total_free,
                   srs.total_free_with_dcs = t.total_free_with_dcs;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END init_sch_room_stats;

    /**
    * returns the surgery scheduling status
    *
    * @param i_lang     language id    
    * @param i_prof     Profissional identification
    * @param o_status   Cursor with the surgery status    
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.x
    * @date    19-05-2009
    */
    FUNCTION get_surgery_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SURGERY_STATUS';
    BEGIN
        g_error := 'OPEN O_STATUS CURSOR';
        OPEN o_status FOR
            SELECT to_char(g_all) data,
                   pk_message.get_message(i_lang, g_msg_all_surg_status) label,
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
              FROM dual
            UNION ALL
            SELECT to_char(pk_wtl_pbl_core.g_wtl_search_st_no_surgery) data,
                   pk_message.get_message(i_lang, g_msg_nosurgery) label,
                   g_no flg_select,
                   5 order_field
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
    END get_surgery_status;

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
    * @author                                Jose Antunes
    * @version                               2.5
    * @since                                 2009/05/20
    **********************************************************************************************/
    FUNCTION confirm_schedules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30) := 'CONFIRM_SCHEDULES';
        l_id_schedule schedule.id_schedule%TYPE;
    
    BEGIN
    
        g_error := 'UPDATE SCHEDULE_BED TEMPORARY FLAG';
        UPDATE schedule_bed sb
           SET sb.flg_temporary = g_no
         WHERE id_schedule IN (SELECT column_value
                                 FROM TABLE(i_tab_id_schedule));
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END confirm_schedules;

    /**
    * Gets a set of inpatient schedules.
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_department                Department ID
    * @param i_id_room                      Room ID
    * @param i_id_bed                       Dep_clin_serv ID
    * @param i_id_dcs                       Dep_clin_serv ID
    * @param i_start_date                   Begin date
    * @param i_end_date                     End date
    * @param i_flg_wizard                   Type of wizard (CA - Cancel, CO - Confirm)
    * @param o_schedules                    Schedules 
    * @param o_error                        Error message if something goes wrong
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/05/28
    */
    FUNCTION get_related_schedules
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ward    IN table_number,
        i_id_spec    IN table_number,
        i_id_adm_phy IN table_number,
        i_start_date IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        i_flg_wizard IN VARCHAR2,
        o_schedules  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_RELATED_SCHEDULES';
        l_dt_begin  TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end    TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_ward   table_number;
    
    BEGIN
    
        g_error := 'CALL PK_DATE_UTILS.GET_STRING_TSTZ';
        pk_date_utils.set_dst_time_check_off;
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
        pk_date_utils.set_dst_time_check_on;
    
        g_error := 'OPEN o_schedules';
        OPEN o_schedules FOR
        
            SELECT s.id_schedule,
                   pk_schedule_oris.get_month_abrev(i_lang,
                                                    pk_date_utils.date_month_tsz(i_lang,
                                                                                 s.dt_begin_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)) || ' ' ||
                   pk_date_utils.date_dayyear_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) begin_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) begin_hour,
                   pk_schedule_oris.get_month_abrev(i_lang,
                                                    pk_date_utils.date_month_tsz(i_lang,
                                                                                 s.dt_end_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)) || ' ' ||
                   pk_date_utils.date_dayyear_tsz(i_lang, s.dt_end_tstz, i_prof.institution, i_prof.software) || ' ' ||
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_end_tstz, i_prof.institution, i_prof.software) end_date,
                   --pk_patient.get_patient_name(i_lang, sg.id_patient) pat_name,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, NULL) pat_name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   pk_wtl_pbl_core.get_prof_string(i_lang, i_prof, sb.id_waiting_list, NULL, 'A') professional,
                   pk_schedule.string_dep_clin_serv(i_lang, s.id_dcs_requested) desc_dcs,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room,
                   pk_translation.get_translation(i_lang, d.code_department) service,
                   pk_translation.get_translation(i_lang, i.code_institution) location
              FROM schedule         s,
                   room             r,
                   sch_group        sg,
                   schedule_bed     sb,
                   department       d,
                   bed              b,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   institution      i
             WHERE s.id_room = r.id_room
               AND s.id_schedule = sg.id_schedule
               AND s.id_schedule = sb.id_schedule
               AND r.id_department = d.id_department
               AND s.id_instit_requested = i.id_institution
               AND sb.id_bed = b.id_bed
               AND s.id_dcs_requested = dcs.id_dep_clin_serv
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND s.id_sch_event = g_inp_sch_event
               AND s.flg_status != pk_schedule.g_status_canceled
                  -- exclude the registered episodes
               AND pk_inp_episode.is_epis_registered(i_lang, s.id_episode) = pk_alert_constant.g_no
                  --
               AND sb.flg_temporary = CASE
                       WHEN i_flg_wizard = 'CO' THEN
                        g_yes
                       ELSE
                        sb.flg_temporary
                   END
               AND (i_id_ward IS NULL OR cardinality(i_id_ward) = 0 OR
                   r.id_department IN (SELECT *
                                          FROM TABLE(i_id_ward)))
               AND cs.id_clinical_service IN (SELECT *
                                                FROM TABLE(i_id_spec))
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

    /**
    * returns the overview legend
    *
    * @param i_lang     language id    
    * @param i_prof     Profissional identification
    * @param o_legend   Cursor with the legend data   
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Sofia Mendes
    * @version 2.5.x
    * @date    20-05-2009
    */
    FUNCTION get_overview_legend
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_legend OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(30) := 'GET_REQUISITION_STATUS';
        l_tab_locations_ids     table_number;
        l_tab_dep_clin_serv_ids table_number := table_number();
        l_tab_locations_names   table_varchar;
        l_locations_list        table_number;
        l_locations             pk_types.cursor_type;
    BEGIN
        g_error := 'CALL get_locations';
        IF NOT get_locations(i_lang => i_lang, i_prof => i_prof, o_locations => l_locations, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_locations';
        FETCH l_locations BULK COLLECT
            INTO l_tab_locations_ids, l_tab_locations_names;
        CLOSE l_locations;
        l_locations_list := l_tab_locations_ids MULTISET UNION DISTINCT table_number(0);
    
        g_error := 'CALL GET_ROOM_DCS_LIST';
        IF NOT (get_room_dcs_list(i_lang, l_tab_locations_ids, l_tab_dep_clin_serv_ids, o_error))
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN O_LEGEND CURSOR';
        OPEN o_legend FOR
            SELECT color_name, label, g_color_prefix || hex_color AS hex_color
              FROM (SELECT sc.id_institution,
                           sc.color_name AS color_name,
                           pk_message.get_message(i_lang, 'SCH_T544') AS label,
                           sc.color_hex AS hex_color,
                           0 AS rank
                      FROM sch_color sc
                     WHERE sc.color_name = 'FREE_BEDS_WITHOUT_SPEC'
                       AND flg_type = 'N'
                    UNION
                    SELECT sc.id_institution,
                           sc.color_name,
                           pk_message.get_message(i_lang, 'SCH_T545') AS label,
                           sc.color_hex AS hex_color,
                           1 AS rank
                      FROM sch_color sc
                     WHERE sc.color_name = 'BLOCKED_BEDS'
                       AND flg_type = 'N'
                    UNION
                    SELECT sc.id_institution,
                           sc.color_name,
                           pk_message.get_message(i_lang, 'SCH_T546') AS label,
                           sc.color_hex AS hex_color,
                           2 AS rank
                      FROM sch_color sc
                     WHERE sc.color_name = 'OCCUPIED_BEDS'
                       AND flg_type = 'N'
                    UNION
                    SELECT sc.id_institution,
                           sc.color_name,
                           pk_message.get_message(i_lang, 'SCH_T547') AS label,
                           sc.color_hex AS hex_color,
                           3 AS rank
                      FROM sch_color sc
                     WHERE sc.color_name = 'TOTAL_BEDS'
                       AND flg_type = 'N'
                    UNION
                    SELECT sc.id_institution,
                           sc.color_name,
                           pk_message.get_message(i_lang, 'SCH_T565') AS label,
                           sc.color_hex AS hex_color,
                           4 AS rank
                      FROM sch_color sc
                     WHERE sc.color_name = g_multi_specs
                       AND flg_type = 'N'
                    UNION
                    SELECT sc.id_institution,
                           sc.color_name,
                           pk_message.get_message(i_lang, 'SCH_T570') AS label,
                           sc.color_hex AS hex_color,
                           5 AS rank
                      FROM sch_color sc
                     WHERE sc.color_name = g_no_specialty
                       AND flg_type = 'N'
                    UNION
                    SELECT sc.id_institution,
                           to_char(sc.id_dep_clin_serv),
                           REPLACE(pk_message.get_message(i_lang, 'SCH_T548'),
                                   '@1',
                                   pk_schedule_oris.get_dep_clin_serv_name(i_lang, NULL, sc.id_dep_clin_serv, NULL)) AS label,
                           sc.color_hex AS hex_color,
                           sc.id_dep_clin_serv AS rank
                      FROM sch_color sc
                     WHERE flg_type = 'D'
                       AND sc.id_dep_clin_serv IN (SELECT column_value
                                                     FROM TABLE(l_tab_dep_clin_serv_ids)))
             WHERE id_institution IN (SELECT column_value
                                        FROM TABLE(l_locations_list))
             ORDER BY rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_legend);
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
    END get_overview_legend;

    /**
    * init slots for a specified bed
    *
    * @param i_lang     language id    
    * @param i_prof     Profissional identification
    * @param i_id_bed   bed id    
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Telmo
    * @version 2.5
    * @date    20-05-2009
    */
    FUNCTION init_bed_slot
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'INIT_BED_SLOT';
        v_dummy     NUMBER;
    
        CURSOR l_cur IS
            SELECT dt_begin_tstz, dt_end_tstz
              FROM schedule s
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
             WHERE sb.id_bed = i_id_bed
               AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
               AND s.flg_status = pk_schedule.g_status_scheduled
             ORDER BY s.dt_begin_tstz;
    
        l_rec               l_cur%ROWTYPE;
        l_curr_begin        TIMESTAMP WITH LOCAL TIME ZONE;
        l_currday           TIMESTAMP WITH LOCAL TIME ZONE;
        l_min_slot_interval NUMBER;
    BEGIN
        pk_date_utils.set_dst_time_check_off;
        l_currday := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        pk_date_utils.set_dst_time_check_on;
    
        -- Get configuration for minimum time that must exists between slots and schedules
        g_error := 'GET CONFIGURATION FOR SCH_MIN_SLOT_INTERVAL';
        BEGIN
            l_min_slot_interval := nvl(to_number(pk_sysconfig.get_config(g_sch_min_slot_interval, i_prof)), 0);
        EXCEPTION
            WHEN OTHERS THEN
                l_min_slot_interval := 0;
        END;
    
        -- delete existing slots
        g_error := 'CLEAN EXISTING SLOTS FOR THIS BED';
        DELETE sch_bed_slot s
         WHERE s.id_bed = i_id_bed;
    
        -- no slots. create them. If there are schedules for this bed, create slots round them schedules
        g_error := 'FETCH VALID SCHEDULES FOR THIS BED';
        OPEN l_cur;
        LOOP
            FETCH l_cur
                INTO l_rec;
            EXIT WHEN l_cur%NOTFOUND;
        
            --calc slot begin date
            IF l_curr_begin IS NULL
            THEN
                g_error := 'CALC PRIMORDIAL DATE';
                -- slot inicial 
                IF l_rec.dt_begin_tstz < l_currday
                THEN
                    l_curr_begin := nvl(l_rec.dt_end_tstz, l_rec.dt_begin_tstz);
                ELSE
                    l_curr_begin := l_currday;
                    INSERT INTO sch_bed_slot
                        (id_bed, dt_begin, dt_end)
                    VALUES
                        (i_id_bed, l_curr_begin, l_rec.dt_begin_tstz);
                    l_curr_begin := l_rec.dt_end_tstz;
                END IF;
            ELSE
                g_error := 'INSERT SLOT';
                -- slots seguintes
                IF (pk_date_utils.get_timestamp_diff(l_rec.dt_begin_tstz, l_curr_begin) * 1440) > l_min_slot_interval
                THEN
                    INSERT INTO sch_bed_slot
                        (id_bed, dt_begin, dt_end)
                    VALUES
                        (i_id_bed, l_curr_begin, l_rec.dt_begin_tstz);
                END IF;
                l_curr_begin := l_rec.dt_end_tstz;
            END IF;
        
        END LOOP;
        CLOSE l_cur;
    
        -- arrematar com slot final ate ao seculo do buck rogers
        g_error := 'INSERT FINAL SLOT';
        INSERT INTO sch_bed_slot
            (id_bed, dt_begin, dt_end)
        VALUES
            (i_id_bed, nvl(l_curr_begin, g_slot_floor), g_slot_ceiling);
    
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
    END init_bed_slot;

    /**
    * recalc slots for a specified bed. Should be used within create_schedule and cancel_schedule and possibly others.
    * optimized to recalc only the area around i_dt_begin and i_dt_end.
    *
    * @param i_lang         language id    
    * @param i_prof         Profissional identification
    * @param i_id_bed       bed id
    * @param i_id_schedule  schedule just created/cancelled
    *
    * @param o_error    error stuff
    *
    * returns true (ok) or false (error)
    *
    * @author  Telmo
    * @version 2.5
    * @date    20-05-2009
    */
    FUNCTION create_slots
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_bed      IN bed.id_bed%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(30) := 'CREATE_SLOTS';
        l_sch_dt_begin schedule.dt_begin_tstz%TYPE;
        l_sch_dt_end   schedule.dt_end_tstz%TYPE;
        l_flg_status   schedule.flg_status%TYPE;
    
        l_max_dt_end        schedule.dt_end_tstz%TYPE;
        l_min_dt_begin      schedule.dt_begin_tstz%TYPE;
        l_min_slot_interval NUMBER;
        --        l_currday           TIMESTAMP WITH LOCAL TIME ZONE := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
    BEGIN
        -- Get configuration for minimum time that must exist between slots and schedules
        g_error := 'GET CONFIGURATION FOR SCH_MIN_SLOT_INTERVAL';
        BEGIN
            l_min_slot_interval := nvl(to_number(pk_sysconfig.get_config(g_sch_min_slot_interval, i_prof)), 0);
        EXCEPTION
            WHEN OTHERS THEN
                l_min_slot_interval := 0;
        END;
    
        -- get schedule dt_begin and dt_end
        SELECT dt_begin_tstz, dt_end_tstz, flg_status
          INTO l_sch_dt_begin, l_sch_dt_end, l_flg_status
          FROM schedule
         WHERE id_schedule = i_id_schedule;
    
        -- get closest lower neighbour's end date. mmight not exist
        SELECT MAX(dt_end_tstz)
          INTO l_max_dt_end
          FROM schedule s
          JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE sb.id_bed = i_id_bed
           AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
           AND s.flg_status = pk_schedule.g_status_scheduled
           AND s.dt_end_tstz <= l_sch_dt_begin
           AND s.id_schedule <> i_id_schedule;
    
        -- if not found, set it to today
        l_max_dt_end := nvl(l_max_dt_end, g_slot_floor);
    
        -- get closest higher neighbour's begin date. Might not exist
        SELECT MIN(dt_begin_tstz)
          INTO l_min_dt_begin
          FROM schedule s
          JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE sb.id_bed = i_id_bed
           AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
           AND s.flg_status = pk_schedule.g_status_scheduled
           AND s.dt_begin_tstz >= l_sch_dt_end
           AND s.id_schedule <> i_id_schedule;
    
        -- if not found, set it to the day the earth stood still
        l_min_dt_begin := nvl(l_min_dt_begin, g_slot_ceiling);
    
        -- delete slots affected by this disturbance in the force
        g_error := 'CLEAN EXISTING SLOTS FOR THIS BED';
        DELETE sch_bed_slot s
         WHERE s.id_bed = i_id_bed
           AND s.dt_begin >= l_max_dt_end
           AND s.dt_end <= l_min_dt_begin;
    
        -- create new slots if there is enough room
        IF (pk_date_utils.get_timestamp_diff(l_min_dt_begin, l_max_dt_end) * 1440) > l_min_slot_interval
        THEN
        
            -- cancelled status - new slot from l_max_dt_end straight to l_min_dt_begin
            IF l_flg_status = pk_schedule.g_status_canceled
            THEN
                INSERT INTO sch_bed_slot
                    (id_bed, dt_begin, dt_end)
                VALUES
                    (i_id_bed, l_max_dt_end, l_min_dt_begin);
            
                -- non-cancelled status - new slot from l_max_dt_end to l_sch_dt_begin and another from l_sch_dt_end to l_min_dt_begin
            ELSE
                IF (pk_date_utils.get_timestamp_diff(l_sch_dt_begin, l_max_dt_end) * 1440) > l_min_slot_interval
                THEN
                    INSERT INTO sch_bed_slot
                        (id_bed, dt_begin, dt_end)
                    VALUES
                        (i_id_bed, l_max_dt_end, l_sch_dt_begin);
                END IF;
            
                IF (pk_date_utils.get_timestamp_diff(l_min_dt_begin, l_sch_dt_end) * 1440) > l_min_slot_interval
                THEN
                    INSERT INTO sch_bed_slot
                        (id_bed, dt_begin, dt_end)
                    VALUES
                        (i_id_bed, l_sch_dt_end, l_min_dt_begin);
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
            RETURN FALSE;
    END create_slots;

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
    * @since                                 2009/05/21
    *
    * UPDATED                                Do not send to clipboard if the schedule is cancelled
    * @author                                Sofia Mendes
    * @version                               V.2.5.0.6.1
    * @since                                 2009/10/08
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
        l_func_name  VARCHAR2(30) := 'SEND_TO_CLIPBOARD';
        l_sch_status schedule.flg_status%TYPE;
    BEGIN
        --verify if the schedule is not cancelled
    
        SELECT s.flg_status
          INTO l_sch_status
          FROM schedule s
         WHERE s.id_schedule = i_id_schedule;
    
        IF (l_sch_status <> pk_schedule.g_sch_canceled)
        THEN
            g_error := 'INSERT SCH_CLIPBOARD';
            INSERT INTO sch_clipboard
                (id_schedule, id_prof_created, dt_creation)
            VALUES
                (i_id_schedule, i_prof.id, current_timestamp);
        END IF;
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

    /**
    * Cancel a set of INP schedules.
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
    * Cancel a set of INP schedules.
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_schedule                  Schedule ID
    * @param i_id_cancel_reason             Cancel reason
    * @param i_cancel_notes                 Cancel notes
    * @param i_transaction_id               Scheduler 3.0 transaction ID
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
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'CANCEL_SCHEDULES';
        o_list_schedules table_number;
    
        --Scheduler 3.0 transaction ID
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
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
                                       i_transaction_id   => l_transaction_id,
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

    /** retrieves a list of rooms that, within the period from i_dt_begin to i_dt_end, 
    *   do no have other patients of different gender in their beds.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_patient                     pivot patient
    * @param i_id_dep                         dep in which to search
    * @param i_dt_begin                       start period
    * @param i_Dt_end                         end period
    * @param o_id_room_list                   output
    * @param o_error                          error data
    *
    * @return                                Success / fail
    *
    * @author                                Telmo
    * @version                               2.5
    * @date                                 27-05-2007
    */
    FUNCTION get_non_unisex_rooms
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_dep       IN department.id_department%TYPE,
        i_dt_begin     IN schedule.dt_begin_tstz%TYPE,
        i_dt_end       IN schedule.dt_end_tstz%TYPE,
        o_id_room_list OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_NON_UNISEX_ROOMS';
        l_gender    patient.gender%TYPE;
    BEGIN
        -- init output list
        o_id_room_list := table_number();
    
        --get patient gender
        g_error := 'GET PATIENT GENDER';
        SELECT gender
          INTO l_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        -- get output list
        g_error := 'GET OUTPUT';
        SELECT DISTINCT id_room
          BULK COLLECT
          INTO o_id_room_list
          FROM department d
          JOIN room r
            ON d.id_department = r.id_department
         WHERE d.flg_available = g_yes
           AND r.flg_available = g_yes
           AND r.id_department = i_id_dep
           AND NOT EXISTS
         (SELECT 1
                  FROM schedule s
                  JOIN sch_group sg
                    ON s.id_schedule = sg.id_schedule
                  JOIN patient p
                    ON sg.id_patient = p.id_patient
                 WHERE s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
                   AND (s.dt_begin_tstz BETWEEN i_dt_begin AND i_dt_end OR s.dt_end_tstz BETWEEN i_dt_begin AND i_dt_end)
                   AND s.flg_status <> pk_schedule.g_status_canceled
                   AND s.id_room = r.id_room
                   AND p.id_patient <> i_id_patient
                   AND p.gender <> l_gender);
    
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
    END get_non_unisex_rooms;

    /** retrieve data from admission request and others sources. Needed for validate functions
    *
    * @param i_id_wl              chosen waiting list id 
    * @param i_unscheduled        N = all  Y = only non scheduled
    * @param o_id_patient         WL DATA - Patient id
    * @param o_id_adm_indic       WL DATA - indication for admission 
    * @param o_id_prof_dest       WL DATA - prof responsible for admission
    * @param o_id_dest_inst       WL DATA - requested location
    * @param o_id_department      WL DATA - requested ward
    * @param o_id_dcs             WL DATA - requested speciality
    * @param o_id_room_type       WL DATA - requested room type
    * @param o_id_pref_room       WL DATA - preferred room
    * @param o_id_adm_type        WL DATA - requested admission type
    * @param o_flg_mix_nurs       WL DATA - N = patient requires room with no mixed genders
    * @param o_id_bed_type        WL DATA - requested bed type
    * @param o_dt_admission       WL DATA - requested date for admission
    * @param o_exp_duration       WL DATA - expected duration
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Telmo
    * @version  2.5
    * @date     22-05-2009
    */
    FUNCTION get_adm_request_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_wl               IN waiting_list.id_waiting_list%TYPE,
        i_unscheduled         IN VARCHAR2 DEFAULT 'Y',
        o_id_patient          OUT waiting_list.id_patient%TYPE,
        o_id_adm_indic        OUT adm_request.id_adm_indication%TYPE,
        o_id_prof_dest        OUT adm_request.id_dest_prof%TYPE,
        o_id_dest_inst        OUT adm_request.id_dest_inst%TYPE,
        o_id_department       OUT adm_request.id_department%TYPE,
        o_id_dcs              OUT adm_request.id_dep_clin_serv%TYPE,
        o_id_room_type        OUT adm_request.id_room_type%TYPE,
        o_id_pref_room        OUT adm_request.id_pref_room%TYPE,
        o_id_adm_type         OUT adm_request.id_admission_type%TYPE,
        o_flg_mix_nurs        OUT adm_request.flg_mixed_nursing%TYPE,
        o_id_bed_type         OUT adm_request.id_bed_type%TYPE,
        o_dt_admission        OUT adm_request.dt_admission%TYPE,
        o_id_episode          OUT adm_request.id_dest_episode%TYPE,
        o_exp_duration        OUT adm_request.expected_duration%TYPE,
        o_id_external_request OUT waiting_list.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_ADM_REQUEST_DATA';
    BEGIN
        g_error := 'GET ADM_REQUEST DATA';
        SELECT wl.id_patient,
               ar.id_adm_indication,
               ar.id_dest_prof,
               ar.id_dest_inst,
               ar.id_department,
               ar.id_dep_clin_serv,
               ar.id_room_type,
               ar.id_pref_room,
               ar.id_admission_type,
               ar.flg_mixed_nursing,
               ar.id_bed_type,
               ar.dt_admission,
               ar.id_dest_episode,
               ar.expected_duration,
               wl.id_external_request
          INTO o_id_patient,
               o_id_adm_indic,
               o_id_prof_dest,
               o_id_dest_inst,
               o_id_department,
               o_id_dcs,
               o_id_room_type,
               o_id_pref_room,
               o_id_adm_type,
               o_flg_mix_nurs,
               o_id_bed_type,
               o_dt_admission,
               o_id_episode,
               o_exp_duration,
               o_id_external_request
          FROM adm_request ar
          JOIN wtl_epis we
            ON ar.id_dest_episode = we.id_episode
          JOIN waiting_list wl
            ON we.id_waiting_list = wl.id_waiting_list
         WHERE we.id_waiting_list = i_id_wl
           AND wl.flg_type IN (pk_wtl_prv_core.g_wtlist_type_bed, pk_wtl_prv_core.g_wtlist_type_both)
           AND (i_unscheduled = g_no OR we.flg_status <> pk_wtl_prv_core.g_wtlist_status_schedule);
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
    END get_adm_request_data;

    /**
    * Determines if the given schedule information follow schedule rules : 
    *  general rules: see function pk_schedule.validate_schedule
    *  specific rules: see inline comments below
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is calling this
    * @param i_dt_begin           input begin date
    * @param i_dt_end             input end date
    * @param i_id_bed             input bed
    * @param i_id_wl              input waiting list id
    * @param i_id_patient         WL DATA - Patient identification
    * @param i_id_adm_indic       WL DATA - requested indication for admission
    * @param i_id_dest_inst       WL DATA - requested location
    * @param i_id_department      WL DATA - requested ward
    * @param i_id_dcs             WL DATA - requested speciality
    * @param i_id_room_type       WL DATA - requested room type
    * @param i_id_pref_room       WL DATA - preferred room
    * @param i_id_adm_type        WL DATA - requested admission type
    * @param i_flg_mix_nurs       WL DATA - (I)= indiferente (N)=requer quarto nao misto
    * @param i_id_bed_type        WL DATA - requested bed type
    * @param i_dt_admission       WL DATA - preferred admission date
    * @param i_id_prof_dest       WL DATA - prof resp. for this admission
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show
    * @param o_surg_bef_adm       warns flash that: Y = surgery before admission is happening  N=all is well
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Telmo
    * @version  2.5
    * @date     21-05-2009
    *
    * UPDATED: 
    * @author   Sofia Mendes
    * @version  2.5.0.5
    * @date     28-07-2009
    */
    FUNCTION validate_schedule_internal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dt_begin       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_id_bed         IN bed.id_bed%TYPE,
        i_id_wl          IN waiting_list.id_waiting_list%TYPE,
        i_id_patient     IN waiting_list.id_patient%TYPE,
        i_id_adm_indic   IN adm_request.id_adm_indication%TYPE,
        i_id_dest_inst   IN adm_request.id_dest_inst%TYPE,
        i_id_department  IN adm_request.id_department%TYPE,
        i_id_dcs         IN adm_request.id_dep_clin_serv%TYPE,
        i_id_room_type   IN adm_request.id_room_type%TYPE,
        i_id_pref_room   IN adm_request.id_pref_room%TYPE,
        i_id_adm_type    IN adm_request.id_admission_type%TYPE,
        i_flg_mix_nurs   IN adm_request.flg_mixed_nursing%TYPE,
        i_id_bed_type    IN adm_request.id_bed_type%TYPE,
        i_dt_admission   IN adm_request.dt_admission%TYPE,
        i_id_prof_dest   IN adm_request.id_dest_prof%TYPE,
        o_flg_proceed    OUT VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_surg_bef_adm   OUT VARCHAR2,
        o_nch_short      OUT VARCHAR2,
        o_nch_short_data OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'VALIDATE_SCHEDULE_INTERNAL';
        l_stoperror BOOLEAN := FALSE;
        l_msg_stack pk_schedule.t_msg_stack;
        l_dt_begin  TIMESTAMP WITH TIME ZONE;
        l_dt_end    TIMESTAMP WITH TIME ZONE;
        l_dummy     NUMBER;
        i           INTEGER;
        l_no_bed  EXCEPTION;
        l_no_slot EXCEPTION;
        l_bad_bed EXCEPTION;
        l_dt_admission TIMESTAMP WITH TIME ZONE;
        l_pat_unavs    pk_wtl_pbl_core.t_rec_unavailabilities;
        l_message      VARCHAR2(2000);
        l_sch_overlap  VARCHAR2(1);
        l_rec_episodes pk_wtl_pbl_core.t_rec_episodes;
        l_avail        VARCHAR2(1);
        l_room_list    table_number;
        l_beginday     TIMESTAMP WITH LOCAL TIME ZONE;
        l_endday       TIMESTAMP WITH LOCAL TIME ZONE;
        l_day          TIMESTAMP WITH LOCAL TIME ZONE;
        l_nch_first    NUMBER;
        l_nch_change   NUMBER;
        l_nch_second   NUMBER;
    
        l_service_nch NUMBER;
        l_needed      NUMBER;
        l_avail_nchs  NUMBER;
        l_total_nchs  NUMBER;
        l_capacity    NUMBER;
        --l_day_idx     NUMBER := 1;
        l_count_day NUMBER := 1;
    
        l_list_avail_nchs  table_number := table_number();
        l_list_needed_nchs table_number := table_number();
        l_list_dates       table_timestamp_tz := table_timestamp_tz();
        l_list_capacity    table_number := table_number();
    
        l_id_nch_level nch_level.id_nch_level%TYPE;
    
        CURSOR c_bed_data IS
            SELECT b.id_bed_type, r.id_room, r.id_room_type, d.id_department, b.flg_status
              FROM bed b
              JOIN room r
                ON b.id_room = r.id_room
              JOIN department d
                ON r.id_department = d.id_department
             WHERE b.id_bed = i_id_bed
               AND b.flg_available = g_yes
               AND r.flg_available = g_yes
               AND d.id_institution = i_id_dest_inst
               AND d.flg_available = g_yes;
    
        r_bed_data c_bed_data%ROWTYPE;
    
    BEGIN
        o_flg_proceed  := g_yes;
        o_flg_show     := g_no;
        o_surg_bef_adm := g_no;
    
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
    
        -- RULE 1: existence of a slot with enough room is mandatory. STOP ERROR. 
        IF i_id_bed IS NULL
        THEN
            RAISE l_no_bed;
        ELSE
            IF NOT is_slot_available(i_lang     => i_lang,
                                     i_id_bed   => i_id_bed,
                                     i_dt_begin => l_dt_begin,
                                     i_dt_end   => l_dt_end,
                                     o_avail    => l_avail,
                                     o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_avail = g_no
            THEN
                RAISE l_no_slot;
            END IF;
        END IF;
    
        -- RULE 2: check other bed and room attributes. STOP ERROR
        -- This is where we fetch bed data
        OPEN c_bed_data;
        FETCH c_bed_data
            INTO r_bed_data;
        IF NOT c_bed_data%FOUND
        THEN
            RAISE l_bad_bed;
        END IF;
        CLOSE c_bed_data;
    
        -- RULE 3: no overlap with other schedules. These might not be visible in the slots so we 
        -- need to compare with schedule dt_begin and dt_end. STOP ERROR
        IF NOT is_bed_available(i_lang     => i_lang,
                                i_id_bed   => i_id_bed,
                                i_dt_begin => l_dt_begin,
                                i_dt_end   => l_dt_end,
                                o_avail    => l_avail,
                                o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_avail = g_no
        THEN
            RAISE l_no_slot;
        END IF;
    
        -- RULE 4: bed type should match requested bed type
        IF i_id_bed_type IS NOT NULL
           AND i_id_bed_type <> r_bed_data.id_bed_type
        THEN
            pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_bed_type_mismatch), 1);
        END IF;
    
        -- RULE 5: room type should match requested room type
        IF i_id_room_type IS NOT NULL
           AND i_id_room_type <> r_bed_data.id_room_type
        THEN
            pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_room_type_mismatch), 1);
        END IF;
    
        -- RULE 6: ward should match preferred ward from request
        IF i_id_department IS NOT NULL
           AND i_id_department <> r_bed_data.id_department
        THEN
            pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_ward_mismatch), 1);
        END IF;
    
        -- RULE 7: room should match admission preferred room 
        IF i_id_pref_room IS NOT NULL
           AND i_id_pref_room <> r_bed_data.id_room
        THEN
            pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_room_mismatch), 1);
        END IF;
    
        -- RULE 8: ward's indication for admission should match admission indication
        IF i_id_adm_indic IS NOT NULL
        THEN
            BEGIN
                /*SELECT 1
                 INTO l_dummy
                 FROM escape_department ed
                WHERE ed.id_department = r_bed_data.id_department
                  AND ed.id_adm_indication = i_id_adm_indic
                  AND rownum = 1;*/
                --Sofia Mendes (18-09-2009): ALERT-45053
                SELECT 1
                  INTO l_dummy
                  FROM (SELECT 1
                          FROM escape_department ed
                         WHERE ed.id_department = r_bed_data.id_department
                           AND ed.id_adm_indication = i_id_adm_indic
                        UNION
                        SELECT 1
                          FROM adm_ind_dep_clin_serv aidcs
                          JOIN dep_clin_serv dcs
                            ON (dcs.id_dep_clin_serv = aidcs.id_dep_clin_serv)
                          JOIN department d
                            ON (d.id_department = dcs.id_department)
                         WHERE aidcs.id_adm_indication = i_id_adm_indic
                           AND aidcs.flg_available = pk_alert_constant.g_yes
                           AND d.flg_available = pk_alert_constant.g_yes
                           AND d.id_department =
                               decode(r_bed_data.id_department, NULL, d.id_department, r_bed_data.id_department))
                 WHERE rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_adm_ind), 1);
            END;
        END IF;
    
        -- RULE 9: surgery before admission. Special case: only sets o_surg_bef_adm
        IF NOT pk_wtl_pbl_core.get_episodes(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_id_waiting_list => i_id_wl,
                                            i_id_epis_type    => pk_wtl_prv_core.g_id_epis_type_surgery,
                                            i_flg_status      => pk_wtl_prv_core.g_wtlist_status_schedule,
                                            o_episodes        => l_rec_episodes,
                                            o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_rec_episodes.exists(1)
        THEN
            BEGIN
                SELECT g_yes
                  INTO o_surg_bef_adm
                  FROM schedule s
                  JOIN schedule_sr sr
                    ON s.id_schedule = sr.id_schedule
                 WHERE s.id_schedule = l_rec_episodes(1).id_schedule
                   AND s.dt_begin_tstz < l_dt_begin
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    o_surg_bef_adm := g_no;
            END;
        END IF;
    
        -- RULE 10: validacao da data recomendada de agendamento
        IF i_dt_admission IS NOT NULL
        THEN
            g_error := 'CALL GET_STRING_TSTZ FOR i_dt_admission';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_dt_admission,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_dt_admission,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
            -- compare with l_dt_begin
            pk_date_utils.set_dst_time_check_off;
            IF pk_date_utils.trunc_insttimezone(i_prof, l_dt_admission) <>
               pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin)
            THEN
                pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_dt_admission), 1);
            END IF;
            pk_date_utils.set_dst_time_check_on;
        END IF;
    
        -- RULE 11: indisponibilidade do paciente
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
    
        --RULE 12: tipo de admissao deve coincidir com o do departamento
        IF i_id_adm_type IS NOT NULL
        THEN
            BEGIN
                SELECT 1
                  INTO l_dummy
                  FROM department d
                 WHERE d.id_department = r_bed_data.id_department
                   AND d.id_admission_type = i_id_adm_type;
            EXCEPTION
                WHEN no_data_found THEN
                    pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_id_adm_type), 1);
            END;
        END IF;
    
        -- RULE 13: especialidade da requisicao deve fazer parte das especialidades do departamento
        IF i_id_dcs IS NOT NULL
        THEN
            BEGIN
                SELECT 1
                  INTO l_dummy
                  FROM dep_clin_serv d
                 WHERE d.id_department = r_bed_data.id_department
                   AND d.id_dep_clin_serv = i_id_dcs;
            EXCEPTION
                WHEN no_data_found THEN
                    pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_id_dcs), 1);
            END;
        END IF;
    
        -- RULE 14: mixed nursing 
        IF i_flg_mix_nurs = g_no
        THEN
            IF NOT get_non_unisex_rooms(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_id_patient   => i_id_patient,
                                        i_id_dep       => r_bed_data.id_department,
                                        i_dt_begin     => l_dt_begin,
                                        i_dt_end       => l_dt_end,
                                        o_id_room_list => l_room_list,
                                        o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_room_list IS NOT NULL
            THEN
                BEGIN
                    SELECT 1
                      INTO l_dummy
                      FROM TABLE(l_room_list) t
                     WHERE t.column_value = r_bed_data.id_room
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        pk_schedule.message_push(pk_message.get_message(i_lang, g_msg_mix_nursing), 1);
                END;
            END IF;
        
        END IF;
    
        -- RULE XX: indication for admission deve coincidir com a do departamento
    
        -- RULE XX: se a cama esta ocupada vai tentar determinar uma data de alta para ver se da em conflito com este agendamento
        /*        IF r_bed_data.flg_status = g_bed_occupied
                THEN
                
                END IF;
        */
        --RULE 15: verify if there is future shortness of nursing care hours
        pk_date_utils.set_dst_time_check_off;
        l_beginday := pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin);
        l_endday   := pk_date_utils.trunc_insttimezone(i_prof, l_dt_end);
        pk_date_utils.set_dst_time_check_on;
    
        -- iterate all days within the period i_dt_begin -> i_dt_end.
        g_error     := 'START LOOP';
        o_nch_short := g_no;
        l_day       := l_beginday;
        WHILE l_day <= l_endday
        LOOP
            g_error := 'CALL get_needed_nchs';
            IF NOT pk_nch_pbl.get_nch_value(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_adm_indication => i_id_adm_indic,
                                            i_nr_day            => l_count_day,
                                            o_nch_value         => l_needed,
                                            o_id_nch_level      => l_id_nch_level,
                                            o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL CALC_AVAILABLE_NCHS';
            IF NOT calc_available_nchs(i_lang          => i_lang,
                                  i_prof          => i_prof,
                                  i_id_department => r_bed_data.id_department,
                                  i_start_date    => CASE
                                                         WHEN l_day = l_beginday THEN
                                                          l_dt_begin
                                                         ELSE
                                                          l_day
                                                     END,
                                  i_end_date      => CASE
                                                         WHEN l_day = l_endday THEN
                                                          l_dt_end
                                                         ELSE
                                                          l_day + 1
                                                     END,
                                  o_avail_nchs    => l_avail_nchs,
                                  o_total_nchs    => l_total_nchs,
                                  o_error         => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL calc_nchs_capacity';
            IF NOT calc_nchs_capacity(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_total_nch  => l_total_nchs,
                                      i_avail_nch  => l_avail_nchs,
                                      i_needed_nch => l_needed,
                                      o_capacity   => l_capacity,
                                      o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- get nch from service   
        
            g_error := 'CALC AVAILABLE AND NEEDED NCHS';
            IF (l_avail_nchs - l_needed < 0)
            THEN
                IF (o_nch_short = g_no OR o_nch_short IS NULL)
                THEN
                    o_nch_short := g_yes;
                END IF;
            
                l_list_dates.extend(1);
                l_list_dates(l_list_dates.last) := l_day;
                l_list_avail_nchs.extend(1);
                l_list_avail_nchs(l_list_avail_nchs.last) := l_avail_nchs;
                l_list_needed_nchs.extend(1);
                l_list_needed_nchs(l_list_needed_nchs.last) := l_needed;
                l_list_capacity.extend(1);
                l_list_capacity(l_list_capacity.last) := l_capacity;
            END IF;
        
            -- get patient needed nchs
            l_day := l_day + INTERVAL '1' DAY;
        
            l_count_day := l_count_day + 1;
        END LOOP;
    
        IF (o_nch_short = g_yes)
        THEN
            g_error := 'OPEN o_nch_short_data CURSOR';
            OPEN o_nch_short_data FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, t_dates.date_short, i_prof) AS date_occur,
                       --pk_date_utils.date_send_tsz(i_lang, l_date_tz_local, i_prof) dt_begin,
                       t_needed.needed_nchs || pk_message.get_message(i_lang, g_msg_hour_indicator) AS nch_needed,
                       t_avail_nch.avail_nchs || pk_message.get_message(i_lang, g_msg_hour_indicator) AS nch_avail,
                       t_capacity.capacity || pk_message.get_message(i_lang, g_msg_percentage) AS capacity,
                       'SCH_WaitingConflictIcon' AS icon,
                       CASE
                            WHEN capacity >= pk_sysconfig.get_config(g_nch_capacity_excess, i_prof) THEN
                             '0xC3000A'
                            ELSE
                             '0xF6D300'
                        END AS color,
                       (SELECT pk_translation.get_translation(i_lang, d.code_department)
                          FROM department d
                         WHERE d.id_department = r_bed_data.id_department) AS department_name
                  FROM (SELECT rownum AS index_date, column_value AS date_short
                          FROM TABLE(l_list_dates)) t_dates,
                       (SELECT rownum AS index_needed, column_value AS needed_nchs
                          FROM TABLE(l_list_needed_nchs)) t_needed,
                       (SELECT rownum AS index_avail, column_value AS avail_nchs
                          FROM TABLE(l_list_avail_nchs)) t_avail_nch,
                       (SELECT rownum AS index_capacity, column_value AS capacity
                          FROM TABLE(l_list_capacity)) t_capacity
                 WHERE t_dates.index_date = t_needed.index_needed
                   AND t_needed.index_needed = t_avail_nch.index_avail
                   AND t_avail_nch.index_avail = t_capacity.index_capacity;
        
        ELSE
            pk_types.open_my_cursor(o_nch_short_data);
        END IF;
    
        -- THE OTHER USUAL RULES
        g_error := 'CALL PK_SCHEDULE.VALIDATE_SCHEDULE';
        IF NOT pk_schedule.validate_schedule(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_id_patient       => i_id_patient,
                                             i_id_sch_event     => g_inp_sch_event,
                                             i_id_dep_clin_serv => i_id_dcs,
                                             i_id_prof          => i_id_prof_dest,
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
                l_stoperror := l_msg_stack.idxmsg = pk_schedule.g_begindatelower OR l_msg_stack.idxmsg = g_stop_error;
                i           := pk_schedule.g_msg_stack.next(i);
            END LOOP;
        
            -- acrescenta o botao de prosseguir se essa mensagem nao esta' na stack
            IF NOT nvl(l_stoperror, FALSE)
            THEN
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
        WHEN l_no_slot THEN
            o_msg_title   := pk_message.get_message(i_lang, g_msg_not_enough_time_header);
            o_button      := pk_schedule.g_r_button_code || pk_message.get_message(i_lang, pk_schedule.g_r_button_code);
            o_msg         := pk_message.get_message(i_lang, g_msg_not_enough_time);
            o_flg_show    := g_yes;
            o_flg_proceed := g_yes;
            pk_types.open_my_cursor(o_nch_short_data);
            RETURN TRUE;
        WHEN l_bad_bed THEN
            o_msg_title   := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_button      := pk_schedule.g_r_button_code || pk_message.get_message(i_lang, pk_schedule.g_r_button_code);
            o_msg         := pk_message.get_message(i_lang, g_msg_bad_bed);
            o_flg_show    := g_yes;
            o_flg_proceed := g_yes;
            pk_types.open_my_cursor(o_nch_short_data);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_nch_short_data);
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
    * Wrapper for validate_schedule_internal to be used for validating schedules coming from the WL.
    * Flash layer must use this one.
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is calling this
    * @param i_dt_begin           input begin date
    * @param i_dt_end             input end date
    * @param i_id_bed             input bed
    * @param i_id_wl              input waiting list id 
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.        
    * @param o_flg_show           Set if a message is displayed or not 
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_button             Buttons to show
    * @param o_surg_bef_adm       warns flash that: Y = surgery before admission is happening  N=all is well and fine
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Telmo
    * @version  2.5
    * @date     22-05-2009
    */

    FUNCTION validate_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dt_begin       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_id_bed         IN bed.id_bed%TYPE,
        i_id_wl          IN schedule_sr.id_waiting_list%TYPE,
        o_flg_proceed    OUT VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_surg_bef_adm   OUT VARCHAR2,
        o_nch_short      OUT VARCHAR2,
        o_nch_short_data OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(32) := 'VALIDATE_SCHEDULE';
        l_id_patient          waiting_list.id_patient%TYPE;
        l_id_adm_indic        adm_request.id_adm_indication%TYPE;
        l_id_prof_dest        adm_request.id_dest_prof%TYPE;
        l_id_dest_inst        adm_request.id_dest_inst%TYPE;
        l_id_department       adm_request.id_department%TYPE;
        l_id_dcs              adm_request.id_dep_clin_serv%TYPE;
        l_id_room_type        adm_request.id_room_type%TYPE;
        l_id_pref_room        adm_request.id_pref_room%TYPE;
        l_id_adm_type         adm_request.id_admission_type%TYPE;
        l_flg_mix_nurs        adm_request.flg_mixed_nursing%TYPE;
        l_id_bed_type         adm_request.id_bed_type%TYPE;
        l_dt_admission        adm_request.dt_admission%TYPE;
        l_id_episode          adm_request.id_dest_episode%TYPE;
        l_exp_duration        adm_request.expected_duration%TYPE;
        l_id_external_request waiting_list.id_external_request%TYPE;
    BEGIN
    
        -- fetch adm request data
        g_error := 'FETCH ADMISSION REQUEST DATA';
        IF NOT get_adm_request_data(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_wl               => i_id_wl,
                                    i_unscheduled         => g_yes,
                                    o_id_patient          => l_id_patient,
                                    o_id_adm_indic        => l_id_adm_indic,
                                    o_id_prof_dest        => l_id_prof_dest,
                                    o_id_dest_inst        => l_id_dest_inst,
                                    o_id_department       => l_id_department,
                                    o_id_dcs              => l_id_dcs,
                                    o_id_room_type        => l_id_room_type,
                                    o_id_pref_room        => l_id_pref_room,
                                    o_id_adm_type         => l_id_adm_type,
                                    o_flg_mix_nurs        => l_flg_mix_nurs,
                                    o_id_bed_type         => l_id_bed_type,
                                    o_dt_admission        => l_dt_admission,
                                    o_id_episode          => l_id_episode,
                                    o_exp_duration        => l_exp_duration,
                                    o_id_external_request => l_id_external_request,
                                    o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- call the working validate
        g_error := 'CALL VALIDATE_SCHEDULE_INTERNAL';
        IF NOT validate_schedule_internal(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_dt_begin       => i_dt_begin,
                                          i_dt_end         => i_dt_end,
                                          i_id_bed         => i_id_bed,
                                          i_id_wl          => i_id_wl,
                                          i_id_patient     => l_id_patient,
                                          i_id_adm_indic   => l_id_adm_indic,
                                          i_id_dest_inst   => l_id_dest_inst,
                                          i_id_department  => l_id_department,
                                          i_id_dcs         => l_id_dcs,
                                          i_id_room_type   => l_id_room_type,
                                          i_id_pref_room   => l_id_pref_room,
                                          i_id_adm_type    => l_id_adm_type,
                                          i_flg_mix_nurs   => l_flg_mix_nurs,
                                          i_id_bed_type    => l_id_bed_type,
                                          i_dt_admission   => l_dt_admission,
                                          i_id_prof_dest   => l_id_prof_dest,
                                          o_flg_proceed    => o_flg_proceed,
                                          o_flg_show       => o_flg_show,
                                          o_msg            => o_msg,
                                          o_msg_title      => o_msg_title,
                                          o_button         => o_button,
                                          o_surg_bef_adm   => o_surg_bef_adm,
                                          o_nch_short      => o_nch_short,
                                          o_nch_short_data => o_nch_short_data,
                                          o_error          => o_error)
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_schedule;

    /**********************************************************************************************
    * This function returns the discharges time (nr of minutes since the begin of the day) of a service.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date    
    * @param i_service                       Department ID    
    * @param o_admission_time                Admission Hour    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/21
    **********************************************************************************************/
    FUNCTION get_admission_time
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_service        IN department.id_department%TYPE,
        o_admission_time OUT sch_inp_dep_time.admission_time%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ADMISSION_TIME';
    BEGIN
        g_error := 'SELECT ADMISSION TIME';
        SELECT sidt.admission_time
          INTO o_admission_time
          FROM sch_inp_dep_time sidt
         WHERE sidt.id_department = i_service;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            SELECT g_default_begin_day
              INTO o_admission_time
              FROM dual;
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_admission_time;

    /**********************************************************************************************
    * This function returns the ward detail info.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_location                      Institution/Location ID
    * @param i_ward                          Department ID    
    * @param o_general_info                  Output cursor with ward general information
    * @param o_floors                        Output cursor with floors
    * @param o_rooms_beds                    Output cursor with the nr of beds per room of the ward
    * @param o_adm_indications               Output cursor with the indications for admission that prefer this ward
    * @param o_free_with_dcs                 Output cursor with the nr of free beds by dep_clin_serv
    * @param o_text                          Text with formatted data
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/21
    **********************************************************************************************/
    FUNCTION get_ward_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_date            IN VARCHAR2,
        i_location        IN institution.id_institution%TYPE,
        i_ward            IN department.id_department%TYPE,
        o_general_info    OUT pk_types.cursor_type,
        o_floors          OUT pk_types.cursor_type,
        o_rooms_beds      OUT pk_types.cursor_type,
        o_adm_indications OUT pk_types.cursor_type,
        o_free_with_dcs   OUT pk_types.cursor_type,
        o_total_nchs      OUT NUMBER,
        o_avail_nchs      OUT NUMBER,
        o_nch_capacity    OUT VARCHAR2,
        o_blocked         OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(30) := 'GET_WARD_DETAIL';
        l_date            TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_admission_time  sch_inp_dep_time.admission_time%TYPE;
        l_dep_info        pk_types.cursor_type;
        l_department      NUMBER;
        l_default_dep_nch PLS_INTEGER;
        l_nch_avail       NUMBER;
    
        l_truncated_date TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_error := 'CONVERT INPUT DATE FROM STRING TO TSTZ FORMAT';
        pk_date_utils.set_dst_time_check_off;
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error          := 'CALL pk_date_utils.trunc_insttimezone';
        l_truncated_date := pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => l_date);
        pk_date_utils.set_dst_time_check_on;
    
        OPEN o_floors FOR
            SELECT pk_translation.get_translation(i_lang, f.code_floors) AS floor_name
              FROM floors f
              JOIN floors_institution fi
                ON f.id_floors = fi.id_floors
              JOIN floors_department fd
                ON fd.id_floors_institution = fi.id_floors_institution
             WHERE id_department = i_ward
               AND f.flg_available = pk_alert_constant.g_yes
               AND fi.flg_available = pk_alert_constant.g_yes
               AND fd.flg_available = pk_alert_constant.g_yes
             ORDER BY 1;
    
        -- indications for admission this ward is responsible for
        g_error := 'CALL PK_WTL_PBL_CORE.GET_ADM_INDICATION';
        IF NOT pk_wtl_pbl_core.get_adm_indication(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_ward           => i_ward,
                                                  o_adm_indication => o_adm_indications,
                                                  o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- ward general info
        g_error := 'OPEN O_GENERAL_INFO';
        OPEN o_general_info FOR
            SELECT d.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) location_name,
                   d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) AS ward_name,
                   COUNT(1) AS nr_rooms,
                   SUM(total_beds) AS nr_beds,
                   --SUM(total_blocked) AS total_blocked,
                   SUM(total_occupied) AS total_occupied,
                   SUM(total_free) AS total_free,
                   nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type)) AS admission_type
              FROM sch_room_stats srs
              JOIN department d
                ON srs.id_department = d.id_department
              JOIN institution i
                ON i.id_institution = d.id_institution
              LEFT JOIN admission_type at
                ON d.id_admission_type = at.id_admission_type
             WHERE i.id_institution = i_location
               AND d.id_department = i_ward
               AND dt_day = to_number(to_char(l_date, 'J'))
             GROUP BY d.id_institution,
                      i.code_institution,
                      d.id_department,
                      d.code_department,
                      nvl(at.desc_admission_type, pk_translation.get_translation(i_lang, at.code_admission_type));
    
        -- nr of beds per room
        g_error := 'OPEN O_ROOMS_BEDS';
        OPEN o_rooms_beds FOR
            SELECT srs.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) AS room_name,
                   total_beds AS total_beds
              FROM sch_room_stats srs
              JOIN department d
                ON srs.id_department = d.id_department
              JOIN room r
                ON srs.id_room = r.id_room
             WHERE d.id_department = i_ward
               AND d.id_institution = i_location
               AND dt_day = to_number(to_char(current_timestamp, 'J'));
    
        -- get admission time
        g_error := 'CALL GET_ADMISSION_TIME';
        IF NOT get_admission_time(i_lang           => i_lang,
                                  i_prof           => i_prof,
                                  i_service        => i_ward,
                                  o_admission_time => l_admission_time,
                                  o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- nr of free beds per dep_clin_serv
        g_error := 'OPEN O_FREE_WITH_DCS';
        OPEN o_free_with_dcs FOR
            SELECT d.id_department,
                   pk_schedule_oris.get_dep_clin_serv_name(i_lang, i_prof, bdcs.id_dep_clin_serv, NULL) AS specialty,
                   COUNT(CASE
                              WHEN bdcs.id_dep_clin_serv IS NULL THEN
                               NULL
                              ELSE
                               1
                          END) AS total_with_dcs,
                   bdcs.id_dep_clin_serv
              FROM department d
              JOIN room r
                ON (r.id_department = d.id_department)
              JOIN bed b
                ON (b.id_room = r.id_room)
              JOIN bed_dep_clin_serv bdcs
                ON b.id_bed = bdcs.id_bed
             WHERE d.flg_available = pk_alert_constant.g_yes
               AND r.flg_available = pk_alert_constant.g_yes
               AND b.flg_available = pk_alert_constant.g_yes
               AND bdcs.flg_available = pk_alert_constant.g_yes
               AND b.id_bed NOT IN (SELECT b.id_bed
                                      FROM schedule s
                                      JOIN schedule_bed sb
                                        ON s.id_schedule = sb.id_schedule
                                      JOIN bed b
                                        ON sb.id_bed = b.id_bed
                                     WHERE s.flg_status != pk_schedule.g_status_canceled
                                       AND pk_date_utils.add_to_ltstz(l_truncated_date, l_admission_time) BETWEEN
                                           s.dt_begin_tstz AND s.dt_end_tstz)
               AND d.id_institution = i_location
               AND d.id_department = i_ward
             GROUP BY d.id_institution, d.id_department, bdcs.id_dep_clin_serv;
    
        -- total nursing care hours        
        g_error := 'CALL pk_bmng_pbl.get_total_department_info';
        IF NOT pk_bmng_pbl.get_total_department_info(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_department  => table_number(i_ward),
                                                     i_institution => NULL,
                                                     i_dt_request  => trunc(l_date),
                                                     o_dep_info    => l_dep_info,
                                                     o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_dep_info';
        FETCH l_dep_info
            INTO l_department, o_blocked, l_nch_avail, o_total_nchs;
        CLOSE l_dep_info;
    
        -- available nursing care hours
        IF (o_total_nchs IS NOT NULL)
        THEN
            g_error := 'CALL calc_available_nchs';
            IF NOT calc_available_nchs(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_id_department => i_ward,
                                       i_start_date    => trunc(l_date),
                                       i_end_date      => trunc(l_date) + 1,
                                       i_total_nchs    => o_total_nchs,
                                       i_dep_nch       => l_nch_avail,
                                       o_avail_nchs    => o_avail_nchs,
                                       o_error         => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- capacity        
            g_error := 'CALL calc_nchs_capacity';
            IF NOT calc_nchs_capacity(i_lang      => i_lang,
                                      i_prof      => i_prof,
                                      i_total_nch => o_total_nchs,
                                      i_avail_nch => o_avail_nchs,
                                      o_capacity  => o_nch_capacity,
                                      o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF o_nch_capacity IS NOT NULL
            THEN
                o_nch_capacity := o_nch_capacity || pk_message.get_message(i_lang, g_msg_percentage);
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_general_info);
            pk_types.open_my_cursor(o_rooms_beds);
            pk_types.open_my_cursor(o_free_with_dcs);
            pk_types.open_my_cursor(o_adm_indications);
            o_total_nchs   := 0;
            o_avail_nchs   := 0;
            o_nch_capacity := '0' || pk_message.get_message(i_lang, g_msg_percentage);
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
    END get_ward_detail;

    /**********************************************************************************************
    * This function returns the ward detail info. Is shall be used when it is being done the admission 
    * schedule and there is a surgery schedule (associated to the same requisition) before the
    * admission schedule.
    * 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_waiting_list               Waiting list id
    * @param i_dt_begin_sch                  Start date of the schedule
    * @param i_dt_end_sch                    End date of the schedule    
    * @param i_id_bed                        Bed id (of the schedule)
    * @param i_id_location                   Location/Institution id 
    * @param o_schedules                     Output cursor with the schedule    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/22
    **********************************************************************************************/
    FUNCTION get_planned_schedulings
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_dt_begin_sch    IN VARCHAR2,
        i_dt_end_sch      IN VARCHAR2,
        i_id_bed          IN bed.id_bed%TYPE,
        o_schedules       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PLANNED_SCHEDULINGS';
        l_id_room   room.id_room%TYPE;
    
        l_dt_begin TIMESTAMP WITH TIME ZONE;
        l_dt_end   TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR dt_begin';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin_sch,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end_sch,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'SELECT room id';
        SELECT r.id_room
          INTO l_id_room
          FROM department d
          JOIN room r
            ON d.id_department = r.id_department
          JOIN bed b
            ON r.id_room = b.id_room
         WHERE b.id_bed = i_id_bed;
    
        g_error := 'OPEN o_schedules cursor';
        OPEN o_schedules FOR
            SELECT pk_date_utils.to_char_insttimezone(i_lang, i_prof, ps.dt_begin_tstz, g_month_day_format) AS start_date,
                   pk_date_utils.date_year_tsz(i_lang, ps.dt_begin_tstz, i_prof.institution, i_prof.software) AS start_date_year,
                   pk_date_utils.date_char_hour_tsz(i_lang, ps.dt_begin_tstz, i_prof.institution, i_prof.software) AS start_hour,
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, ps.dt_end_tstz, g_month_day_format) AS end_date,
                   pk_date_utils.date_year_tsz(i_lang, ps.dt_end_tstz, i_prof.institution, i_prof.software) AS end_date_year,
                   pk_date_utils.date_char_hour_tsz(i_lang, ps.dt_end_tstz, i_prof.institution, i_prof.software) AS end_hour,
                   ps.scheduling,
                   pk_translation.get_translation(i_lang, i.code_institution) location_name,
                   pk_translation.get_translation(i_lang, d.code_department) AS department_name,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) AS room_name,
                   ps.flg_status,
                   ps.flg_temporary,
                   CASE
                        WHEN ps.flg_status IS NOT NULL THEN
                         decode(ps.flg_status,
                                g_scheduled,
                                decode(ps.flg_temporary,
                                       g_yes,
                                       pk_sysdomain.get_img(i_lang, g_bed_flg_temp, g_yes),
                                       pk_sysdomain.get_img(i_lang, pk_schedule.g_schedule_flg_status_domain, ps.flg_status)),
                                pk_sysdomain.get_img(i_lang, pk_schedule.g_schedule_flg_status_domain, ps.flg_status))
                    END icon_sch_status,
                   r.id_department,
                   r.id_room
              FROM (SELECT s.dt_begin_tstz,
                           s.dt_end_tstz,
                           pk_message.get_message(i_lang, g_msg_surgery) AS scheduling,
                           s.id_room AS room,
                           s.flg_status,
                           ssr.flg_temporary
                      FROM schedule s
                      JOIN schedule_sr ssr
                        ON s.id_schedule = ssr.id_schedule
                     WHERE ssr.id_waiting_list = i_id_waiting_list
                          --AND s.flg_status = g_scheduled
                       AND s.id_sch_consult_vacancy IS NOT NULL
                    UNION ALL
                    SELECT l_dt_begin AS dt_begin_tstz,
                           l_dt_end AS dt_begin_tstz,
                           pk_message.get_message(i_lang, g_msg_bed) AS scheduling,
                           l_id_room AS room,
                           '' AS flg_status,
                           '' AS flg_temporary
                      FROM dual) ps,
                   room r,
                   department d,
                   institution i
             WHERE ps.room = r.id_room
               AND d.id_department = r.id_department
               AND i.id_institution = d.id_institution
             ORDER BY ps.dt_begin_tstz;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedules);
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
    END get_planned_schedulings;

    /**********************************************************************************************
    * This function returns the list of locations.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param o_locations                     Output table with the locations ids   
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/25
    **********************************************************************************************/
    FUNCTION get_locations_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_locations OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_LOCATIONS_LIST';
        l_locations           pk_types.cursor_type;
        l_tab_locations_names table_varchar := table_varchar();
    BEGIN
        g_error := 'CALL get_locations';
        IF NOT get_locations(i_lang => i_lang, i_prof => i_prof, o_locations => l_locations, o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_locations';
        FETCH l_locations BULK COLLECT
            INTO o_locations, l_tab_locations_names;
        CLOSE l_locations;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(l_locations);
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
    END get_locations_list;

    /**********************************************************************************************
    * This function returns the list of locations.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param o_locations                     Output table with the locations ids   
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/25
    **********************************************************************************************/
    FUNCTION get_locations
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_locations OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_LOCATIONS';
        l_locations           pk_types.cursor_type;
        l_tab_locations_names table_varchar := table_varchar();
        l_locations_ids       table_number := table_number();
    BEGIN
        g_error := 'CALL pk_admission_request.get_location_list';
        IF NOT pk_admission_request.get_location_list(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_adm_indication => NULL,
                                                      o_list           => l_locations,
                                                      o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_locations';
        FETCH l_locations BULK COLLECT
            INTO l_locations_ids, l_tab_locations_names;
        CLOSE l_locations;
    
        g_error := 'OPEN cursor o_locations';
        IF (l_locations_ids IS NULL OR cardinality(l_locations_ids) = 0)
        THEN
            OPEN o_locations FOR
                SELECT inst.id_institution,
                       pk_translation.get_translation(i_lang, inst.code_institution) institution_desc
                  FROM institution inst
                 WHERE inst.id_institution = i_prof.institution;
        ELSE
            OPEN o_locations FOR
                SELECT loc_ids.location_id AS id_institution, loc_names.location_name AS institution_desc
                  FROM (SELECT rownum AS index_id, column_value AS location_id
                          FROM TABLE(l_locations_ids)) loc_ids,
                       (SELECT rownum AS index_name, column_value AS location_name
                          FROM TABLE(l_tab_locations_names)) loc_names
                 WHERE loc_ids.index_id = loc_names.index_name;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(l_locations);
            pk_types.open_my_cursor(o_locations);
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
    END get_locations;

    /**********************************************************************************************
    * This function returns the list of physicians.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_locations                     List of location ids    
    * @param i_id_location                   Location/Institution id 
    * @param o_data                          Output cursor with the physicians    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/22
    **********************************************************************************************/
    FUNCTION get_physicians
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_locations IN table_number,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PHYSICIANS';
        l_locations table_number;
    BEGIN
    
        IF (i_locations IS NOT NULL AND i_locations.exists(1) AND TRIM(i_locations(1)) IS NOT NULL)
        THEN
            l_locations := i_locations;
        ELSE
            g_error := 'CALL GET_LOCATIONS_LIST';
            IF NOT
                get_locations_list(i_lang => i_lang, i_prof => i_prof, o_locations => l_locations, o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_data FOR
            SELECT p.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                   NULL,
                   NULL
              FROM professional p
             WHERE EXISTS (SELECT 0
                      FROM prof_dep_clin_serv pdcs
                      JOIN prof_institution pi
                        ON (pi.id_professional = pdcs.id_professional)
                      JOIN dep_clin_serv dcs
                        ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                      JOIN department d
                        ON (d.id_department = dcs.id_department AND d.id_institution = pi.id_institution)
                     WHERE d.id_institution IN (SELECT column_value
                                                  FROM TABLE(l_locations))
                       AND pdcs.id_professional = p.id_professional
                       AND pdcs.flg_status = 'S'
                       AND pi.flg_state = pk_alert_constant.g_active
                       AND pk_prof_utils.get_category(i_lang,
                                                      profissional(p.id_professional,
                                                                   pi.id_institution,
                                                                   pk_alert_constant.g_soft_inpatient)) =
                           pk_alert_constant.g_cat_type_doc
                       AND instr(d.flg_type, 'I') > 0)
             ORDER BY name_prof;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
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
    END get_physicians;

    /**********************************************************************************************
    * This function returns the clinical service.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_locations                     List of location ids    
    * @param i_id_location                   Location/Institution id 
    * @param o_data                          Output cursor with the clinical services info    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/22
    **********************************************************************************************/
    FUNCTION get_clinical_services
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_locations IN table_number,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_CLINICAL_SERVICES';
        l_locations table_number;
    BEGIN
        IF (i_locations IS NOT NULL AND i_locations.exists(1) AND TRIM(i_locations(1)) IS NOT NULL)
        THEN
            l_locations := i_locations;
        ELSE
            g_error := 'CALL GET_LOCATIONS_LIST';
            IF NOT
                get_locations_list(i_lang => i_lang, i_prof => i_prof, o_locations => l_locations, o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_data FOR
            SELECT DISTINCT dcs.id_clinical_service,
                            pk_translation.get_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                           dcs.id_clinical_service) clin_serv_desc
              FROM dep_clin_serv dcs
              JOIN department d
                ON (dcs.id_department = d.id_department)
             WHERE d.id_institution IN (SELECT column_value
                                          FROM TABLE(l_locations))
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND EXISTS (SELECT 0
                      FROM adm_ind_dep_clin_serv aidcs
                     WHERE aidcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
             ORDER BY clin_serv_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
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
    END get_clinical_services;

    /** Reschedule validation   
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional doing the reschedule.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_dt_begin               new begin date (direct input)
    * @param i_dt_end                 new end date (direct input)    
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_surg_bef_adm           warns flash that: Y = surgery before admission is happening  N=all is well
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    *
    * @author  Sofia Mendes 
    * @version  2.5.3
    * @date     2009/05/25
    */
    FUNCTION validate_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_bed          IN bed.id_bed%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_surg_bef_adm    OUT VARCHAR2,
        o_nch_short       OUT VARCHAR2,
        o_nch_short_data  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(19) := 'VALIDATE_RESCHEDULE';
        l_id_wl        schedule_bed.id_waiting_list%TYPE;
        l_id_sch_event schedule.id_sch_event%TYPE;
    
        l_id_patient          waiting_list.id_patient%TYPE;
        l_id_adm_indic        adm_request.id_adm_indication%TYPE;
        l_id_prof_dest        adm_request.id_dest_prof%TYPE;
        l_id_dest_inst        adm_request.id_dest_inst%TYPE;
        l_id_department       adm_request.id_department%TYPE;
        l_id_dcs              adm_request.id_dep_clin_serv%TYPE;
        l_id_room_type        adm_request.id_room_type%TYPE;
        l_id_pref_room        adm_request.id_pref_room%TYPE;
        l_id_adm_type         adm_request.id_admission_type%TYPE;
        l_flg_mix_nurs        adm_request.flg_mixed_nursing%TYPE;
        l_id_bed_type         adm_request.id_bed_type%TYPE;
        l_dt_admission        adm_request.dt_admission%TYPE;
        l_id_episode          adm_request.id_dest_episode%TYPE;
        l_exp_duration        adm_request.expected_duration%TYPE;
        l_dummy               VARCHAR2(400);
        l_id_external_request waiting_list.id_external_request%TYPE;
    BEGIN
        SELECT id_sch_event, sb.id_waiting_list
          INTO l_id_sch_event, l_id_wl
          FROM schedule s
          JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE s.id_schedule = i_old_id_schedule;
    
        --universal reschedule rules
        g_error := 'CALL PK_SCHEDULE.VALIDATE_RESCHEDULE';
        IF NOT pk_schedule.validate_reschedule(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_old_id_schedule  => i_old_id_schedule,
                                               i_id_dep_clin_serv => NULL, -- nao enviar este para nao validar
                                               i_id_sch_event     => l_id_sch_event,
                                               i_id_prof          => NULL, -- não é usado para nada o i_id_prof
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
    
        IF (o_flg_proceed = g_yes)
        THEN
            -- inp validation rules
            -- data gata from admission request
            g_error := 'CALL GET_ADM_REQUEST_DATA';
            IF NOT get_adm_request_data(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_wl               => l_id_wl,
                                        i_unscheduled         => g_no,
                                        o_id_patient          => l_id_patient,
                                        o_id_adm_indic        => l_id_adm_indic,
                                        o_id_prof_dest        => l_id_prof_dest,
                                        o_id_dest_inst        => l_id_dest_inst,
                                        o_id_department       => l_id_department,
                                        o_id_dcs              => l_id_dcs,
                                        o_id_room_type        => l_id_room_type,
                                        o_id_pref_room        => l_id_pref_room,
                                        o_id_adm_type         => l_id_adm_type,
                                        o_flg_mix_nurs        => l_flg_mix_nurs,
                                        o_id_bed_type         => l_id_bed_type,
                                        o_dt_admission        => l_dt_admission,
                                        o_id_episode          => l_id_episode,
                                        o_exp_duration        => l_exp_duration,
                                        o_id_external_request => l_id_external_request,
                                        o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL VALIDATE_SCHEDULE_INTERNAL';
            IF NOT validate_schedule_internal(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_dt_begin       => i_dt_begin,
                                              i_dt_end         => i_dt_end,
                                              i_id_bed         => i_id_bed,
                                              i_id_wl          => l_id_wl,
                                              i_id_patient     => l_id_patient,
                                              i_id_adm_indic   => l_id_adm_indic,
                                              i_id_dest_inst   => l_id_dest_inst,
                                              i_id_department  => l_id_department,
                                              i_id_dcs         => l_id_dcs,
                                              i_id_room_type   => l_id_room_type,
                                              i_id_pref_room   => l_id_pref_room,
                                              i_id_adm_type    => l_id_adm_type,
                                              i_flg_mix_nurs   => l_flg_mix_nurs,
                                              i_id_bed_type    => l_id_bed_type,
                                              i_dt_admission   => l_dt_admission,
                                              i_id_prof_dest   => l_id_prof_dest,
                                              o_flg_proceed    => o_flg_proceed,
                                              o_flg_show       => o_flg_show,
                                              o_msg            => o_msg,
                                              o_msg_title      => o_msg_title,
                                              o_button         => o_button,
                                              o_surg_bef_adm   => o_surg_bef_adm,
                                              o_nch_short      => o_nch_short,
                                              o_nch_short_data => o_nch_short_data,
                                              o_error          => o_error)
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
    END validate_reschedule;

    /*
    * Create bed schedule. for internal consumption
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is doing the scheduling
    * @param i_id_patient         Patient id
    * @param i_id_dcs             dcs from the admission request
    * @param i_id_prof            prof responsible for admission
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_tempor         Y=temporary N=definitive
    * @param i_id_room            Room id
    * @param i_id_bed             bed id
    * @param i_id_schedule_ref    old schedule id. Used if this function is called by update_schedule
    * @param i_id_episode         inpatient Episode id
    * @param i_id_wl              waiting list needed here only to be referenced in schedule_sr
    * @param i_id_inst            target institution where this bed belongs
    * @param i_notes              schedule notes
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
    * @date     25-05-2009
    */
    FUNCTION create_schedule_internal
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_prof             IN professional.id_professional%TYPE,
        i_dt_begin            IN VARCHAR2,
        i_dt_end              IN VARCHAR2,
        i_flg_tempor          IN schedule_sr.flg_temporary%TYPE DEFAULT 'Y',
        i_id_room             IN schedule.id_room%TYPE,
        i_id_bed              IN schedule_bed.id_bed%TYPE,
        i_id_schedule_ref     IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_episode          IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_wl               IN waiting_list.id_waiting_list%TYPE,
        i_id_inst             IN institution.id_institution%TYPE,
        i_notes               IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        o_id_schedule         OUT schedule.id_schedule%TYPE,
        o_flg_proceed         OUT VARCHAR2,
        o_flg_show            OUT VARCHAR2,
        o_msg                 OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'CREATE_SCHEDULE_INTERNAL';
        l_id_sch_event sch_event.id_sch_event%TYPE;
        l_dt_begin     TIMESTAMP WITH TIME ZONE;
        l_dt_end       TIMESTAMP WITH TIME ZONE;
        l_no_slot EXCEPTION;
        l_no_bed  EXCEPTION;
        l_avail    VARCHAR2(1);
        l_dep_type sch_event.dep_type%TYPE;
        l_dummy    sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_id_room  bed.id_room%TYPE := i_id_room;
    
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
    
        -- validacoes essenciais
        IF i_id_bed IS NULL
        THEN
            RAISE l_no_bed;
        ELSE
            -- slot available...
            g_error := 'CALL IS_SLOT_AVAILABLE';
            IF NOT is_slot_available(i_lang     => i_lang,
                                     i_id_bed   => i_id_bed,
                                     i_dt_begin => l_dt_begin,
                                     i_dt_end   => l_dt_end,
                                     o_avail    => l_avail,
                                     o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_avail = g_no
            THEN
                RAISE l_no_slot;
            END IF;
            -- ...and double check
            g_error := 'CALL IS_SLOT_AVAILABLE';
            IF NOT is_bed_available(i_lang     => i_lang,
                                    i_id_bed   => i_id_bed,
                                    i_dt_begin => l_dt_begin,
                                    i_dt_end   => l_dt_end,
                                    o_avail    => l_avail,
                                    o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF l_avail = g_no
            THEN
                RAISE l_no_slot;
            END IF;
        END IF;
    
        -- get room if not supplied. Se nao encontrar vai para o when others principal
        g_error := 'GET ROOM ID';
        IF l_id_room IS NULL
        THEN
            SELECT id_room
              INTO l_id_room
              FROM bed
             WHERE id_bed = i_id_bed;
        END IF;
    
        -- Get the event that is actually associated with the vacancies.
        -- It can be a generic event (if the institution has one) or the event itself.
        -- NOTE: the id event here is fixed. If other events are created this code must be changed
        g_error := 'GET GENERIC EVENT';
        IF NOT pk_schedule_common.get_generic_event(i_lang           => i_lang,
                                                    i_id_institution => i_id_inst,
                                                    i_id_event       => g_inp_sch_event,
                                                    o_id_event       => l_id_sch_event,
                                                    o_error          => o_error)
        THEN
            RETURN FALSE;
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
    
        --inserir na schedule e subsidiarias
        g_error := 'CALL PK_SCHEDULE_COMMON.CREATE_SCHEDULE';
        IF NOT pk_schedule_common.create_schedule(i_lang               => i_lang,
                                                  i_id_prof_schedules  => i_prof.id,
                                                  i_id_institution     => i_prof.institution,
                                                  i_id_software        => i_prof.software,
                                                  i_id_patient         => table_number(i_id_patient),
                                                  i_id_dep_clin_serv   => i_id_dcs, -- a instit_requested e' calculada a partir deste
                                                  i_id_sch_event       => l_id_sch_event,
                                                  i_id_prof            => i_id_prof,
                                                  i_dt_begin           => l_dt_begin,
                                                  i_dt_end             => l_dt_end,
                                                  i_flg_vacancy        => pk_schedule_common.g_sched_vacancy_routine,
                                                  i_flg_status         => pk_schedule.g_status_scheduled,
                                                  i_schedule_notes     => i_notes,
                                                  i_id_lang_translator => NULL,
                                                  i_id_lang_preferred  => NULL,
                                                  i_id_reason          => NULL,
                                                  i_id_origin          => NULL,
                                                  i_id_schedule_ref    => i_id_schedule_ref,
                                                  i_id_room            => l_id_room,
                                                  i_flg_sch_type       => l_dep_type,
                                                  i_reason_notes       => NULL,
                                                  i_flg_request_type   => NULL,
                                                  i_flg_schedule_via   => NULL,
                                                  i_id_consult_vac     => NULL,
                                                  o_id_schedule        => o_id_schedule,
                                                  o_occupied           => l_dummy,
                                                  i_ignore_vacancies   => TRUE,
                                                  i_id_episode         => i_id_episode,
                                                  i_id_complaint       => NULL,
                                                  i_id_sch_recursion   => NULL,
                                                  o_error              => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- inserir na schedule_bed
        IF NOT ins_schedule_bed(i_lang             => i_lang,
                                id_schedule_in     => o_id_schedule,
                                id_bed_in          => i_id_bed,
                                id_waiting_list_in => i_id_wl,
                                flg_temporary_in   => i_flg_tempor,
                                flg_conflict_in    => g_no,
                                o_error            => o_error)
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
        IF NOT create_slots(i_lang        => i_lang,
                            i_prof        => i_prof,
                            i_id_bed      => i_id_bed,
                            i_id_schedule => o_id_schedule,
                            o_error       => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- sincro discharge predicted date
        IF NOT pk_discharge.set_discharge_sch_dt(i_lang                  => i_lang,
                                                 i_episode               => i_id_episode,
                                                 i_patient               => i_id_patient,
                                                 i_prof                  => i_prof,
                                                 i_dt_discharge_schedule => i_dt_end,
                                                 o_id_discharge_schedule => l_dummy,
                                                 o_error                 => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- recalc stats in table sch_room_stats
        IF NOT calc_room_stats(i_lang => i_lang, i_prof => i_prof, i_id_schedule => o_id_schedule, o_error => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
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
        WHEN l_no_slot THEN
            o_msg_title   := pk_message.get_message(i_lang, g_msg_not_enough_time_header);
            o_button      := pk_schedule.g_cancel_button_code ||
                             pk_message.get_message(i_lang, pk_schedule.g_cancel_button);
            o_msg         := pk_message.get_message(i_lang, g_msg_not_enough_time);
            o_flg_show    := g_yes;
            o_flg_proceed := g_yes;
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
            RETURN FALSE;
    END create_schedule_internal;

    /*
    * Create bed schedule. 
    *
    * @param i_lang               Language
    * @param i_prof               Professional who is doing the scheduling
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_tempor         Y=temporary N=definitive
    * @param i_id_wl              waiting list id
    * @param i_id_bed             bed id
    * @param i_id_schedule_ref    old schedule id. Used if this function is called by update_schedule
    * @param i_notes              schedule notes
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
    * @date     26-05-2009
    */
    FUNCTION create_schedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_flg_tempor      IN VARCHAR2,
        i_id_wl           IN waiting_list.id_waiting_list%TYPE,
        i_id_bed          IN bed.id_bed%TYPE,
        i_id_schedule_ref IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_notes           IN schedule.schedule_notes%TYPE DEFAULT NULL,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(32) := 'CREATE_SCHEDULE';
        l_id_patient          waiting_list.id_patient%TYPE;
        l_id_adm_indic        adm_request.id_adm_indication%TYPE;
        l_id_prof_dest        adm_request.id_dest_prof%TYPE;
        l_id_dest_inst        adm_request.id_dest_inst%TYPE;
        l_id_department       adm_request.id_department%TYPE;
        l_id_dcs              adm_request.id_dep_clin_serv%TYPE;
        l_id_room_type        adm_request.id_room_type%TYPE;
        l_id_pref_room        adm_request.id_pref_room%TYPE;
        l_id_adm_type         adm_request.id_admission_type%TYPE;
        l_flg_mix_nurs        adm_request.flg_mixed_nursing%TYPE;
        l_id_bed_type         adm_request.id_bed_type%TYPE;
        l_dt_admission        adm_request.dt_admission%TYPE;
        l_id_episode          adm_request.id_dest_episode%TYPE;
        l_exp_duration        adm_request.expected_duration%TYPE;
        l_id_external_request waiting_list.id_external_request%TYPE;
    BEGIN
    
        -- fetch adm request data
        g_error := 'FETCH ADMISSION REQUEST DATA';
        IF NOT get_adm_request_data(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_wl               => i_id_wl,
                                    i_unscheduled         => g_yes,
                                    o_id_patient          => l_id_patient,
                                    o_id_adm_indic        => l_id_adm_indic,
                                    o_id_prof_dest        => l_id_prof_dest,
                                    o_id_dest_inst        => l_id_dest_inst,
                                    o_id_department       => l_id_department,
                                    o_id_dcs              => l_id_dcs,
                                    o_id_room_type        => l_id_room_type,
                                    o_id_pref_room        => l_id_pref_room,
                                    o_id_adm_type         => l_id_adm_type,
                                    o_flg_mix_nurs        => l_flg_mix_nurs,
                                    o_id_bed_type         => l_id_bed_type,
                                    o_dt_admission        => l_dt_admission,
                                    o_id_episode          => l_id_episode,
                                    o_exp_duration        => l_exp_duration,
                                    o_id_external_request => l_id_external_request,
                                    o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT create_schedule_internal(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_patient          => l_id_patient,
                                        i_id_dcs              => l_id_dcs,
                                        i_id_prof             => l_id_prof_dest,
                                        i_dt_begin            => i_dt_begin,
                                        i_dt_end              => i_dt_end,
                                        i_flg_tempor          => i_flg_tempor,
                                        i_id_room             => NULL, --obtido dentro do internal
                                        i_id_bed              => i_id_bed,
                                        i_id_schedule_ref     => i_id_schedule_ref,
                                        i_id_episode          => l_id_episode,
                                        i_id_wl               => i_id_wl,
                                        i_id_inst             => l_id_dest_inst, -- usado apenas para calcular o id_event
                                        i_notes               => i_notes,
                                        i_id_external_request => l_id_external_request,
                                        o_id_schedule         => o_id_schedule,
                                        o_flg_proceed         => o_flg_proceed,
                                        o_flg_show            => o_flg_show,
                                        o_msg                 => o_msg,
                                        o_msg_title           => o_msg_title,
                                        o_button              => o_button,
                                        o_error               => o_error)
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
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_schedule;

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
    * @version 2.5.3
    * @date    26-05-2009
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
    * update an existing schedule
    *
    * @param i_lang                     Language id
    * @param i_prof                     Professional identification
    * @param i_old_id_schedule          ID of schedule that will be updated    
    * @param i_dt_begin                 Schedule Start Date
    * @param i_dt_end                   Schedule End Date
    * @param i_flg_temporary_status     Flag temporary ('Y' - temporary, 'N' - final)        
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
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        i_flg_temporary_status IN schedule_bed.flg_temporary%TYPE DEFAULT NULL,
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
    
        l_cancel_schedule EXCEPTION;
    
        l_dt_begin TIMESTAMP WITH TIME ZONE;
        l_dt_end   TIMESTAMP WITH TIME ZONE;
    
        l_dummy table_number;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule,
                   sb.id_bed,
                   s.dt_begin_tstz,
                   s.dt_end_tstz,
                   sb.flg_temporary,
                   sb.id_waiting_list,
                   s.schedule_notes
              FROM schedule s
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
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
           pk_date_utils.compare_dates_tsz(i_prof, l_sched_rec.dt_end_tstz, l_dt_end) = 'E')
        THEN
            IF (l_sched_rec.flg_temporary != i_flg_temporary_status)
            THEN
                g_error := 'UPDATE TABLE SCHEDULE_BED';
                UPDATE schedule_bed
                   SET flg_temporary = i_flg_temporary_status
                 WHERE id_schedule = i_old_id_schedule;
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
        
            -- create a new schedule
            g_error := 'CALL CREATE_SCHEDULE';
            IF NOT pk_schedule_inp.create_schedule(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_dt_begin        => i_dt_begin,
                                                   i_dt_end          => i_dt_end,
                                                   i_flg_tempor      => i_flg_temporary_status,
                                                   i_id_wl           => l_sched_rec.id_waiting_list,
                                                   i_id_bed          => l_sched_rec.id_bed,
                                                   i_id_schedule_ref => i_old_id_schedule,
                                                   i_notes           => l_sched_rec.schedule_notes,
                                                   o_id_schedule     => o_id_schedule,
                                                   o_flg_proceed     => o_flg_proceed,
                                                   o_flg_show        => o_flg_show,
                                                   o_msg             => o_msg,
                                                   o_msg_title       => o_msg_title,
                                                   o_button          => o_button,
                                                   o_error           => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            
            ELSE
                IF (o_flg_proceed = g_no OR o_id_schedule IS NULL)
                THEN
                    ROLLBACK;
                    RETURN TRUE;
                ELSE
                    g_error := 'CALL SET_CONFLICTS';
                    IF NOT pk_schedule_inp.set_conflicts(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_schedule    => o_id_schedule,
                                                         o_list_schedules => l_dummy,
                                                         o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
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
    * update an existing schedule
    *
    * @param i_lang                     Language id
    * @param i_prof                     Professional identification
    * @param i_old_id_schedule          ID of schedule that will be updated    
    * @param i_dt_begin                 Schedule Start Date
    * @param i_dt_end                   Schedule End Date
    * @param i_flg_temporary_status     Flag temporary ('Y' - temporary, 'N' - final)        
    * @param i_transaction_id           Scheduler 3.0 transaction ID
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
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        i_flg_temporary_status IN schedule_bed.flg_temporary%TYPE DEFAULT NULL,
        i_transaction_id       IN VARCHAR2,
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
    
        l_cancel_schedule EXCEPTION;
    
        l_dt_begin TIMESTAMP WITH TIME ZONE;
        l_dt_end   TIMESTAMP WITH TIME ZONE;
    
        l_dummy table_number;
    
        --Scheduler 3.0 transaction ID
        l_transaction_id VARCHAR2(4000);
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.id_schedule,
                   sb.id_bed,
                   s.dt_begin_tstz,
                   s.dt_end_tstz,
                   sb.flg_temporary,
                   sb.id_waiting_list,
                   s.schedule_notes
              FROM schedule s
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
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
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
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
           pk_date_utils.compare_dates_tsz(i_prof, l_sched_rec.dt_end_tstz, l_dt_end) = 'E')
        THEN
            IF (l_sched_rec.flg_temporary != i_flg_temporary_status)
            THEN
                g_error := 'UPDATE TABLE SCHEDULE_BED';
                UPDATE schedule_bed
                   SET flg_temporary = i_flg_temporary_status
                 WHERE id_schedule = i_old_id_schedule;
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
                                   i_transaction_id   => l_transaction_id,
                                   o_error            => o_error)
            THEN
                RAISE l_cancel_schedule;
            END IF;
        
            -- create a new schedule
            g_error := 'CALL CREATE_SCHEDULE';
            IF NOT pk_schedule_inp.create_schedule(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_dt_begin        => i_dt_begin,
                                                   i_dt_end          => i_dt_end,
                                                   i_flg_tempor      => i_flg_temporary_status,
                                                   i_id_wl           => l_sched_rec.id_waiting_list,
                                                   i_id_bed          => l_sched_rec.id_bed,
                                                   i_id_schedule_ref => i_old_id_schedule,
                                                   i_notes           => l_sched_rec.schedule_notes,
                                                   o_id_schedule     => o_id_schedule,
                                                   o_flg_proceed     => o_flg_proceed,
                                                   o_flg_show        => o_flg_show,
                                                   o_msg             => o_msg,
                                                   o_msg_title       => o_msg_title,
                                                   o_button          => o_button,
                                                   o_error           => o_error)
            THEN
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                ROLLBACK;
                RETURN FALSE;
            
            ELSE
                IF (o_flg_proceed = g_no OR o_id_schedule IS NULL)
                THEN
                    ROLLBACK;
                    pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                    RETURN TRUE;
                ELSE
                    g_error := 'CALL SET_CONFLICTS';
                    IF NOT pk_schedule_inp.set_conflicts(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_id_schedule    => o_id_schedule,
                                                         o_list_schedules => l_dummy,
                                                         o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        
        END IF;
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_schedule;

    /**
    * Calculate and set conflicts
    *
    * @param i_lang                         Language
    * @param i_prof                         Professional identification
    * @param i_id_schedule                  Schedule ID   
    * @param o_error                        Error message if something goes wrong
    *
    * @author                                Jose Antunes
    * @version                               V.2.5
    * @since                                 2009/05/26
    *
    * UPDATED: include the possibility to remove conflicts
    * @author                                Sofia Mendes
    * @version                               V.2.5.0.5
    * @since                                 2009/07/21
    */
    FUNCTION set_conflicts
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_flg_conflict   IN schedule_bed.flg_conflict%TYPE DEFAULT pk_alert_constant.g_yes,
        o_list_schedules OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_CONFLICTS';
        l_id_bed    bed.id_bed%TYPE;
        l_dt_begin  schedule.dt_begin_tstz%TYPE;
        l_dt_end    schedule.dt_end_tstz%TYPE;
    
    BEGIN
    
        g_error := 'GET BED, DT_BEGIN_TSTZ AND DT_END_TSTZ';
        SELECT sb.id_bed, s.dt_begin_tstz, s.dt_end_tstz
          INTO l_id_bed, l_dt_begin, l_dt_end
          FROM schedule s
         INNER JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE s.id_schedule = i_id_schedule;
    
        g_error := 'GET CONFLICT SCHEDULES: i_flg_conflict:' || i_flg_conflict;
        IF (i_flg_conflict = g_yes)
        THEN
            SELECT s.id_schedule
              BULK COLLECT
              INTO o_list_schedules
              FROM schedule s
             INNER JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
             WHERE l_dt_begin <= s.dt_begin_tstz
               AND l_dt_end >= s.dt_begin_tstz
                  --(s.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end OR s.dt_end_tstz BETWEEN l_dt_begin AND l_dt_end)
               AND sb.id_bed = l_id_bed
               AND s.id_sch_event = g_inp_sch_event
               AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
        ELSE
            SELECT s.id_schedule
              BULK COLLECT
              INTO o_list_schedules
              FROM schedule s
             INNER JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
             WHERE (s.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end OR s.dt_end_tstz BETWEEN l_dt_begin AND l_dt_end)
               AND sb.id_bed = l_id_bed
               AND s.id_sch_event = g_inp_sch_event
               AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
        
            o_list_schedules := o_list_schedules MULTISET UNION table_number(i_id_schedule);
        END IF;
    
        g_error := 'UPDATE SCHEDULE_BED CONFLICT FLAG';
        IF ((o_list_schedules.count > 1 AND i_flg_conflict = g_yes) OR i_flg_conflict = g_no)
        THEN
            UPDATE schedule_bed sb
               SET sb.flg_conflict = i_flg_conflict
             WHERE id_schedule IN (SELECT column_value
                                     FROM TABLE(o_list_schedules));
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
    END set_conflicts;

    /** list of search criteria for autopick feature
    *
    * @param i_lang               Language
    * @param i_prof               Professional data
    * @param o_list               output list
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo Castro
    * @version  2.5
    * @date     26-05-2009
    */
    FUNCTION get_autopick_crit
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_AUTOPICK_CRIT';
    BEGIN
        --open cursor
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT id_criteria, pk_translation.get_translation(i_lang, code_criteria) critname
              FROM sch_autopick_crit
             WHERE flg_available = g_yes
             ORDER BY critname;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
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
    END get_autopick_crit;

    /** retrieves beds which fulfill the wl entry and its admission request in all the given criteria 
    *
    * @param i_lang               Language
    * @param i_prof               Professional data
    * @param i_id_wl              wl entry
    * @param i_crit_list          list of criteria ids. search will use all of them
    * @param o_list               output list
    * @param o_error              Error message if something goes wrong
    *
    * @author   Telmo Castro
    * @version  2.5
    * @date     26-05-2009
    */
    FUNCTION get_autopick
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wl     IN waiting_list.id_waiting_list%TYPE,
        i_crit_list IN table_number,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_AUTOPICK';
        l_no_crit EXCEPTION;
        l_id_rooms            table_number;
        l_id_patient          waiting_list.id_patient%TYPE;
        l_id_adm_indic        adm_request.id_adm_indication%TYPE;
        l_id_prof_dest        adm_request.id_dest_prof%TYPE;
        l_id_dest_inst        adm_request.id_dest_inst%TYPE;
        l_id_department       adm_request.id_department%TYPE;
        l_id_dcs              adm_request.id_dep_clin_serv%TYPE;
        l_id_room_type        adm_request.id_room_type%TYPE;
        l_id_pref_room        adm_request.id_pref_room%TYPE;
        l_id_adm_type         adm_request.id_admission_type%TYPE;
        l_flg_mix_nurs        adm_request.flg_mixed_nursing%TYPE;
        l_id_bed_type         adm_request.id_bed_type%TYPE;
        l_dt_admission        adm_request.dt_admission%TYPE;
        l_id_episode          adm_request.id_dest_episode%TYPE;
        l_exp_duration        adm_request.expected_duration%TYPE;
        l_id_external_request waiting_list.id_external_request%TYPE;
    BEGIN
    
        IF i_crit_list IS NULL
           OR i_crit_list.count = 0
        THEN
            RAISE l_no_crit;
        END IF;
    
        -- fetch adm request data
        g_error := 'FETCH ADMISSION REQUEST DATA';
        IF NOT get_adm_request_data(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_wl               => i_id_wl,
                                    i_unscheduled         => g_yes,
                                    o_id_patient          => l_id_patient,
                                    o_id_adm_indic        => l_id_adm_indic,
                                    o_id_prof_dest        => l_id_prof_dest,
                                    o_id_dest_inst        => l_id_dest_inst,
                                    o_id_department       => l_id_department,
                                    o_id_dcs              => l_id_dcs,
                                    o_id_room_type        => l_id_room_type,
                                    o_id_pref_room        => l_id_pref_room,
                                    o_id_adm_type         => l_id_adm_type,
                                    o_flg_mix_nurs        => l_flg_mix_nurs,
                                    o_id_bed_type         => l_id_bed_type,
                                    o_dt_admission        => l_dt_admission,
                                    o_id_episode          => l_id_episode,
                                    o_exp_duration        => l_exp_duration,
                                    o_id_external_request => l_id_external_request,
                                    o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- get output
        g_error := 'GET RESULTS';
        OPEN o_list FOR
            SELECT b.id_bed --, dt_begin, dt_end
              FROM bed b
              JOIN room r
                ON b.id_room = r.id_room
              JOIN department d
                ON r.id_department = d.id_department
             WHERE b.flg_available = g_yes
               AND r.flg_available = g_yes
               AND d.flg_available = g_yes
                  
                  -- admission location
               AND (g_ap_crit_adm_location NOT IN (SELECT *
                                                     FROM TABLE(i_crit_list)) OR
                   (l_id_dest_inst IS NOT NULL AND l_id_dest_inst = d.id_institution))
                  
                  -- nch needed. NO SUPPORT FOR THIS
                  -- AND (g_ap_crit_nch_needed NOT IN (SELECT * FROM TABLE(i_crit_list)))
                  
                  -- admission service
               AND (g_ap_crit_adm_service NOT IN (SELECT *
                                                    FROM TABLE(i_crit_list)) OR
                   (l_id_department IS NOT NULL AND d.id_department = l_id_department))
                  
                  -- admission specialty
               AND (g_ap_crit_adm_specialty NOT IN (SELECT *
                                                      FROM TABLE(i_crit_list)) OR
                   (l_id_dcs IS NOT NULL AND EXISTS
                    (SELECT 1
                        FROM bed_dep_clin_serv rd
                       WHERE rd.id_bed = b.id_bed
                         AND rd.id_dep_clin_serv = l_id_dcs)))
                  
                  -- admission physician
               AND (g_ap_crit_adm_physician NOT IN (SELECT *
                                                      FROM TABLE(i_crit_list)) OR
                   (l_id_prof_dest IS NOT NULL AND EXISTS
                    (SELECT 1
                        FROM prof_dep_clin_serv pd
                        JOIN dep_clin_serv dcs
                          ON pd.id_dep_clin_serv = dcs.id_dep_clin_serv
                       WHERE pd.id_professional = l_id_prof_dest
                         AND dcs.flg_available = g_yes
                         AND dcs.id_department = d.id_department)))
                  
                  -- expected duration
               AND (g_ap_crit_expected_duration NOT IN (SELECT *
                                                          FROM TABLE(i_crit_list)) OR
                   (l_exp_duration IS NOT NULL AND EXISTS
                    (SELECT 1
                        FROM sch_bed_slot sbs
                       WHERE sbs.id_bed = b.id_bed
                         AND sbs.dt_begin > g_sysdate_tstz
                         AND l_exp_duration <= (pk_date_utils.get_timestamp_diff(sbs.dt_end, sbs.dt_begin) * 24))))
                  
                  -- preparation. NO SUPPORT FOR THIS
                  -- AND (g_ap_crit_Preparation NOT IN (SELECT * FROM TABLE(i_crit_list)))
                  
                  -- room type
               AND (g_ap_crit_room_type NOT IN (SELECT *
                                                  FROM TABLE(i_crit_list)) OR
                   (l_id_room_type IS NOT NULL AND r.id_room_type = l_id_room_type));
    
        -- mixed nursing. UNABLE TO DO BECAUSE WE DONT HAVE DT_BEGIN AND DT_END NEEDED FOR FUNCTION GET_NON_UNISEX_ROOMS
        -- AND (g_ap_crit_Mix_nursing NOT IN (SELECT * FROM TABLE(i_crit_list)))
    
        /*
        g_ap_crit_Mix_nursing CONSTANT NUMBER := 9;
        g_ap_crit_bed_type CONSTANT NUMBER := 10;
        g_ap_crit_Prefered_room CONSTANT NUMBER := 11;
        g_ap_crit_surgery_prefered_time CONSTANT NUMBER := 12;
        g_ap_crit_surgery_suggested_date CONSTANT NUMBER := 13;
        g_ap_crit_adm_suggested_date CONSTANT NUMBER := 14;
        g_ap_crit_surgery_date CONSTANT NUMBER := 15;
        g_ap_crit_unav_periods*/
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_crit THEN
            pk_types.open_my_cursor(o_list);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
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
    END get_autopick;

    /**********************************************************************************************
    * This function alters the schedule end date. It is used when the discharge predicted date 
    * is changed.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode ID   
    * @param i_id_patient                    PAtient ID   
    * @param i_date                          New schedule end date    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/25
    **********************************************************************************************/
    FUNCTION set_schedule_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN wtl_epis.id_episode%TYPE,
        i_id_patient IN sch_group.id_patient%TYPE,
        i_date       IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'SET_SCHEDULE_DATE';
        l_id_schedule    schedule.id_schedule%TYPE;
        l_id_bed         bed.id_bed%TYPE;
        l_date           TIMESTAMP WITH LOCAL TIME ZONE;
        l_sch_date_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dummy          table_number;
    BEGIN
        g_error := 'SELECT ID_SCHEDULE';
        SELECT t.id_schedule, t.dt_begin_tstz, t.id_bed
          INTO l_id_schedule, l_sch_date_begin, l_id_bed
          FROM (SELECT s.id_schedule, s.dt_begin_tstz, sb.id_bed
                  FROM schedule s
                  JOIN schedule_bed sb
                    ON s.id_schedule = sb.id_schedule
                  JOIN sch_group sg
                    ON sg.id_schedule = s.id_schedule
                  JOIN wtl_epis we
                    ON sb.id_waiting_list = we.id_waiting_list
                 WHERE we.id_epis_type = pk_wtl_prv_core.g_id_epis_type_inpatient
                   AND s.flg_status = g_active
                   AND we.id_episode = i_id_episode
                   AND sg.id_patient = i_id_patient
                 ORDER BY s.dt_end_tstz DESC) t
         WHERE rownum = 1;
    
        g_error := 'CALL GET_STRING_TSTZ FOR i_date';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- only updates if the new date is more recent than the schedule begin date
        IF (pk_date_utils.compare_dates_tsz(i_prof, l_date, l_sch_date_begin) = 'G')
        THEN
            g_error := 'UPDATE SCHEDULE DT_END_TSTZ';
            UPDATE schedule s
               SET s.dt_end_tstz = l_date
             WHERE s.id_schedule = l_id_schedule;
        
            -- rebuild slots
            IF NOT create_slots(i_lang        => i_lang,
                                i_prof        => i_prof,
                                i_id_bed      => l_id_bed,
                                i_id_schedule => l_id_schedule,
                                o_error       => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL SET_CONFLICTS';
            IF NOT pk_schedule_inp.set_conflicts(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_schedule    => l_id_schedule,
                                                 o_list_schedules => l_dummy,
                                                 o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            -- if no schedule exists (e.g. emergent/temporary pacient), no update needed
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
            RETURN FALSE;
    END set_schedule_date;

    /**********************************************************************************************
    * This function alters the schedule end date. It is used when the discharge predicted date 
    * is changed.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode ID   
    * @param i_id_patient                    PAtient ID   
    * @param i_date                          New schedule end date    
    * @param i_transaction_id                Scheduler 3.0 transaction ID
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/25
    **********************************************************************************************/
    FUNCTION set_schedule_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN wtl_epis.id_episode%TYPE,
        i_id_patient     IN sch_group.id_patient%TYPE,
        i_date           IN VARCHAR2,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'SET_DISCHARGE_SCHEDULE_DATE';
        l_id_schedule    schedule.id_schedule%TYPE;
        l_id_bed         bed.id_bed%TYPE;
        l_date           TIMESTAMP WITH LOCAL TIME ZONE;
        l_sch_date_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dummy          table_number;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'SELECT ID_SCHEDULE';
        SELECT t.id_schedule, t.dt_begin_tstz, t.id_bed
          INTO l_id_schedule, l_sch_date_begin, l_id_bed
          FROM (SELECT s.id_schedule, s.dt_begin_tstz, sb.id_bed
                  FROM schedule s
                  JOIN schedule_bed sb
                    ON s.id_schedule = sb.id_schedule
                  JOIN sch_group sg
                    ON sg.id_schedule = s.id_schedule
                  JOIN wtl_epis we
                    ON sb.id_waiting_list = we.id_waiting_list
                 WHERE we.id_epis_type = pk_wtl_prv_core.g_id_epis_type_inpatient
                   AND s.flg_status = g_active
                   AND we.id_episode = i_id_episode
                   AND sg.id_patient = i_id_patient
                 ORDER BY s.dt_end_tstz DESC) t
         WHERE rownum = 1;
    
        g_error := 'CALL GET_STRING_TSTZ FOR i_date';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- only updates if the new date is more recent than the schedule begin date
        IF (pk_date_utils.compare_dates_tsz(i_prof, l_date, l_sch_date_begin) = 'G')
        THEN
            g_error := 'UPDATE SCHEDULE DT_END_TSTZ IN SCHEDULER 3.0';
            IF NOT pk_schedule_api_upstream.set_schedule_bed(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_schedule     => l_id_schedule,
                                                             i_id_bed          => l_id_bed,
                                                             i_dt_new_end_date => l_date,
                                                             i_transaction_id  => l_transaction_id,
                                                             o_error           => o_error)
            THEN
            
                RAISE l_func_exception;
            END IF;
        
            g_error := 'UPDATE SCHEDULE DT_END_TSTZ';
            UPDATE schedule s
               SET s.dt_end_tstz = l_date
             WHERE s.id_schedule = l_id_schedule;
        
            -- rebuild slots
            IF NOT create_slots(i_lang        => i_lang,
                                i_prof        => i_prof,
                                i_id_bed      => l_id_bed,
                                i_id_schedule => l_id_schedule,
                                o_error       => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL SET_CONFLICTS';
            IF NOT pk_schedule_inp.set_conflicts(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_schedule    => l_id_schedule,
                                                 o_list_schedules => l_dummy,
                                                 o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            -- if no schedule exists (e.g. emergent/temporary pacient), no update needed
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
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        
            RETURN FALSE;
    END set_schedule_date;

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
    * @author                                Sofia Mendes
    * @version                               2.5
    * @since                                 2009-05-27
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_sch_clipboard;

    /**********************************************************************************************
    * This function creates a reschedule (from clipboard).
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_old_id_schedule               Old Schedule Id    
    * @param i_dt_begin                      Start date of the new schedule 
    * @param i_dt_end                        End date of the new schedule
    * @param i_id_bed                   Bed ID
    * @param o_id_schedule              Newly generated schedule id 
    * @param o_flg_proceed              Set to 'Y' if there is additional processing needed.
    * @param o_flg_show                 Set if a message is displayed or not      
    * @param o_msg                      Message body to be displayed in flash
    * @param o_msg_title                Message title
    * @param o_button                   Buttons to show.
    * @param o_error                    Error stuff
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/25
    **********************************************************************************************/
    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_bed          IN bed.id_bed%TYPE,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(19) := 'CREATE_RESCHEDULE';
        l_schedule_cancel_notes schedule.schedule_notes%TYPE;
        l_dt_begin              TIMESTAMP WITH TIME ZONE;
        l_sysdate               TIMESTAMP WITH TIME ZONE := current_timestamp;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.schedule_notes, s.flg_status, sb.flg_temporary, sb.id_waiting_list, sb.id_bed
              FROM schedule s
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
             WHERE s.id_schedule = c_sched.i_old_id_schedule
               AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
    
        l_sched_rec c_sched%ROWTYPE;
    BEGIN
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR DT_BRGIN';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert current date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR CURRENT_TIMESTAMP';
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
    
        -- cancel old schedule 
        g_error := 'CANCEL OLD SCHEDULE';
        IF NOT cancel_schedule(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_schedule      => i_old_id_schedule,
                               i_id_cancel_reason => NULL,
                               i_cancel_notes     => l_schedule_cancel_notes,
                               o_error            => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- create new schedule        
        g_error := 'CREATE NEW SCHEDULE';
        IF NOT pk_schedule_inp.create_schedule(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_dt_begin        => i_dt_begin,
                                               i_dt_end          => i_dt_end,
                                               i_flg_tempor      => l_sched_rec.flg_temporary,
                                               i_id_wl           => l_sched_rec.id_waiting_list,
                                               i_id_bed          => i_id_bed,
                                               i_id_schedule_ref => i_old_id_schedule,
                                               i_notes           => l_sched_rec.schedule_notes,
                                               o_id_schedule     => o_id_schedule,
                                               o_flg_proceed     => o_flg_proceed,
                                               o_flg_show        => o_flg_show,
                                               o_msg             => o_msg,
                                               o_msg_title       => o_msg_title,
                                               o_button          => o_button,
                                               o_error           => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        ELSE
            IF (o_flg_proceed = g_no)
            THEN
                ROLLBACK;
            END IF;
        END IF;
    
        -- remove from professional clipboard
        g_error := 'DELETE FROM PROFESSIONAL CLIPBOARD';
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
    * This function creates a reschedule (from clipboard).
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_old_id_schedule               Old Schedule Id    
    * @param i_dt_begin                      Start date of the new schedule 
    * @param i_dt_end                        End date of the new schedule
    * @param i_id_bed                   Bed ID
    * @param i_transaction_id           Scheduler 3.0 transaction ID
    * @param o_id_schedule              Newly generated schedule id 
    * @param o_flg_proceed              Set to 'Y' if there is additional processing needed.
    * @param o_flg_show                 Set if a message is displayed or not      
    * @param o_msg                      Message body to be displayed in flash
    * @param o_msg_title                Message title
    * @param o_button                   Buttons to show.
    * @param o_error                    Error stuff
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/25
    **********************************************************************************************/
    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_id_bed          IN bed.id_bed%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_proceed     OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(19) := 'CREATE_RESCHEDULE';
        l_schedule_cancel_notes schedule.schedule_notes%TYPE;
        l_dt_begin              TIMESTAMP WITH TIME ZONE;
        l_sysdate               TIMESTAMP WITH TIME ZONE := current_timestamp;
    
        -- Cursor for getting the old schedule's information
        CURSOR c_sched(i_old_id_schedule schedule.id_schedule%TYPE) IS
            SELECT s.schedule_notes, s.flg_status, sb.flg_temporary, sb.id_waiting_list, sb.id_bed
              FROM schedule s
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
             WHERE s.id_schedule = c_sched.i_old_id_schedule
               AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
    
        l_sched_rec c_sched%ROWTYPE;
    
        --Scheduler 3.0 transaction ID
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR DT_BRGIN';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert current date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR CURRENT_TIMESTAMP';
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
    
        -- cancel old schedule 
        g_error := 'CANCEL OLD SCHEDULE';
        IF NOT cancel_schedule(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_schedule      => i_old_id_schedule,
                               i_id_cancel_reason => NULL,
                               i_cancel_notes     => l_schedule_cancel_notes,
                               i_transaction_id   => l_transaction_id,
                               o_error            => o_error)
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- create new schedule        
        g_error := 'CREATE NEW SCHEDULE';
        IF NOT pk_schedule_inp.create_schedule(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_dt_begin        => i_dt_begin,
                                               i_dt_end          => i_dt_end,
                                               i_flg_tempor      => l_sched_rec.flg_temporary,
                                               i_id_wl           => l_sched_rec.id_waiting_list,
                                               i_id_bed          => i_id_bed,
                                               i_id_schedule_ref => i_old_id_schedule,
                                               i_notes           => l_sched_rec.schedule_notes,
                                               o_id_schedule     => o_id_schedule,
                                               o_flg_proceed     => o_flg_proceed,
                                               o_flg_show        => o_flg_show,
                                               o_msg             => o_msg,
                                               o_msg_title       => o_msg_title,
                                               o_button          => o_button,
                                               o_error           => o_error)
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            ROLLBACK;
            RETURN FALSE;
        ELSE
            IF (o_flg_proceed = g_no)
            THEN
                ROLLBACK;
            END IF;
        END IF;
    
        -- remove from professional clipboard
        g_error := 'DELETE FROM PROFESSIONAL CLIPBOARD';
        IF NOT
            del_sch_clipboard(i_lang => i_lang, i_prof => i_prof, i_id_schedule => i_old_id_schedule, o_error => o_error)
        THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_reschedule;

    /**********************************************************************************************
    * This function returns the clinical services associated to an ward/department and/or a room.
    * It should be used before the waiting list search (when the user select an ward or a bed and it is done the wl search)
    * in order to get the list of clinical services to provide to the waiting list search function.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_department                 Department/Ward ID    
    * @param i_id_room                       Room ID 
    * @param o_data                          Output cursor with the physicians    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.3
    * @since                                 2009/05/27
    **********************************************************************************************/
    FUNCTION get_clin_servs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        i_id_room       IN room.id_room%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_CLIN_SERVS';
        l_locations table_number;
    BEGIN
    
        g_error := 'OPEN CURSOR';
        OPEN o_data FOR
            SELECT DISTINCT cs.id_clinical_service,
                            pk_translation.get_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                           dcs.id_clinical_service) clin_serv_desc
              FROM dep_clin_serv dcs
              JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
              JOIN department d
                ON (dcs.id_department = d.id_department)
              JOIN room r
                ON d.id_department = r.id_department
             WHERE (d.id_department = i_id_department OR i_id_department IS NULL)
               AND (r.id_room = i_id_room OR i_id_room IS NULL)
               AND dcs.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
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
    END get_clin_servs;

    /** get begin date of a schedule for the given id. IF several are found, the latest one (create date) is used.
    *   INLINE FUNCTION
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                   episode id
    * 
    * returns           timestamp with local time zone
    *
    * @author                                Telmo
    * @version                               2.5
    * @since                                 28-05-2009
    */
    FUNCTION get_sch_dt_begin
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN schedule.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_dt schedule.dt_begin_tstz%TYPE := NULL;
    BEGIN
        g_error := 'GET DT_BEGIN';
    
        SELECT dt_begin_tstz
          INTO l_dt
          FROM (SELECT s.*, row_number() over(PARTITION BY s.id_episode ORDER BY s.dt_schedule_tstz DESC) rn
                  FROM schedule s
                 WHERE s.id_episode = i_id_episode
                   AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
                   AND s.flg_status != pk_alert_constant.g_cancelled)
         WHERE rn = 1;
    
        RETURN l_dt;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**********************************************************************************************
    * This function returns the grid body information for conflicts view
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Input date
    * @param i_location                      Location ID
    * @param i_ward                          Ward ID
    * @param o_conflicts                     Cursor with conflicts information
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Jose Antunes
    * @version                               2.5
    * @since                                 2009/06/29
    *
    * UPDATED: ALERT-36167 
    * @author                                Sofia Mendes
    * @version                               2.5
    * @since                                 2009/07/16
    *
    * UPDATED: Scheduler/Bed Management integration (schedule/alocation conflicts)
    * @author                                Sofia Mendes
    * @version                               2.5
    * @since                                 2009/07/29
    **********************************************************************************************/
    FUNCTION get_conflicts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN VARCHAR2,
        i_location  IN institution.id_institution%TYPE,
        i_ward      IN department.id_department%TYPE,
        o_conflicts OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_location_name VARCHAR2(400);
        l_func_name     VARCHAR2(30) := 'GET_CONFLICTS';
        l_date          TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_begin_date    TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_end_date      TIMESTAMP(6) WITH LOCAL TIME ZONE;
    
        l_allocations    pk_types.cursor_type;
        l_schs_conflicts table_number := table_number();
        l_schedules      table_number := table_number();
    
        l_alloc_id_bed     bed.id_bed%TYPE;
        l_alloc_id_patient patient.id_patient%TYPE;
        l_alloc_dt_begin   TIMESTAMP WITH LOCAL TIME ZONE;
        l_alloc_dt_end     TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_rec        t_rec_sch_alloc;
        l_tab_allocs t_tab_sch_alloc := t_tab_sch_alloc();
    
        idx_conf NUMBER := 1;
    BEGIN
    
        g_error := 'CONVERT INPUT DATE FROM STRING TO TSTZ FORMAT';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- para cada uma das alocações verificar se há conflito
        g_error := 'CALL pk_bmng_pbl.get_future_allocations_list';
        IF NOT pk_bmng_pbl.get_future_allocations_list(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_department  => table_number(i_ward),
                                                       i_institution => NULL,
                                                       i_dt_request  => trunc(l_date),
                                                       o_alloc_list  => l_allocations,
                                                       o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        LOOP
            g_error := 'LOOP THROUGH l_allocations cursor: bed: ' || l_alloc_id_bed;
            FETCH l_allocations
                INTO l_alloc_id_bed, l_alloc_id_patient, l_alloc_dt_begin, l_alloc_dt_end;
            EXIT WHEN l_allocations%NOTFOUND;
        
            IF (l_alloc_dt_end IS NULL OR l_alloc_dt_end < trunc(l_date) OR
               l_alloc_dt_end < pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof.institution, g_sysdate_tstz))
            THEN
                l_alloc_dt_end := trunc(l_date) + 1;
            END IF;
        
            l_schs_conflicts := table_number();
            g_error          := 'CALL verify_conflict_sch_allocation';
            IF NOT verify_conflict_sch_allocation(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_start_allocation => l_alloc_dt_begin,
                                                  i_end_allocation   => l_alloc_dt_end,
                                                  i_id_bed           => l_alloc_id_bed,
                                                  i_sch_begin_date   => l_date,
                                                  o_schs_conflict    => l_schs_conflicts,
                                                  o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF (l_schs_conflicts.count > 0)
            THEN
                FOR idx IN l_schs_conflicts.first .. l_schs_conflicts.last
                LOOP
                    g_error := 'LOOP THROUGH l_schs_conflicts- id_schedule:' || l_schs_conflicts(idx);
                    l_rec   := t_rec_sch_alloc(l_schs_conflicts(idx),
                                               l_alloc_id_bed,
                                               l_alloc_id_patient,
                                               l_alloc_dt_begin,
                                               l_alloc_dt_end);
                    l_tab_allocs.extend(1);
                    l_tab_allocs(idx_conf) := l_rec;
                
                    l_schedules.extend(1);
                    l_schedules(idx_conf) := l_schs_conflicts(idx);
                    idx_conf := idx_conf + 1;
                END LOOP;
            END IF;
        
        END LOOP;
    
        g_error := 'OPEN CURSOR o_conflicts';
        OPEN o_conflicts FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, s1.dt_begin_tstz, i_prof) dt_begin, --pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) dt_begin,          
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, s1.dt_begin_tstz, 'Mon DD') AS start_date, --pk_date_utils.to_char_insttimezone(i_lang, i_prof, ps.dt_begin_tstz, g_month_day_format) AS start_date,         
                   pk_date_utils.date_year_tsz(i_lang, s1.dt_begin_tstz, i_prof.institution, i_prof.software) AS start_date_year, --pk_date_utils.date_year_tsz(i_lang, ps.dt_begin_tstz, i_prof.institution, i_prof.software) AS start_date_year,
                   pk_date_utils.date_send_tsz(i_lang, s1.dt_end_tstz, i_prof) dt_end, --pk_date_utils.date_send_tsz(i_lang, s.dt_end_tstz, i_prof) dt_end,
                   i.id_institution,
                   pk_translation.get_translation(i_lang, code_institution) AS location,
                   d.id_department,
                   pk_translation.get_translation(i_lang, code_department) AS service,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name,
                   -- o paciente que provocou o conflito
                   s1.id_schedule AS id_schedule_ad,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p1.id_patient, s1.id_episode, s1.id_schedule) photo_ad,
                   pk_patient.get_gender(i_lang, p1.gender) AS gender_ad,
                   pk_patient.get_pat_age(i_lang, p1.id_patient, i_prof) pat_age_ad,
                   pk_patient.get_pat_name(i_lang, i_prof, sg1.id_patient, NULL) patient_name_ad,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg1.id_patient) pat_ad_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg1.id_patient) pat_ad_nd_icon,
                   
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, s1.dt_end_tstz, 'Mon DD') || ' ' ||
                   pk_date_utils.date_year_tsz(i_lang, s1.dt_end_tstz, i_prof.institution, i_prof.software) AS discharge_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s1.dt_end_tstz, i_prof.institution, i_prof.software) AS discharges_hour,
                   -- o paciente que vai entrar
                   s.id_schedule,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, s.id_episode, s.id_schedule) photo,
                   pk_patient.get_gender(i_lang, p.gender) AS gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, NULL) patient_name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   
                   pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) admission_total_date,
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, s.dt_begin_tstz, 'Mon DD') || ' ' ||
                   pk_date_utils.date_year_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) AS admission_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) AS admission_hour,
                   decode(sb.flg_temporary,
                          g_yes,
                          pk_schedule.g_icon_prefix || pk_sysdomain.get_img(i_lang, 'SCHEDULE_BED.CONF_TEMP', 'C'),
                          pk_schedule.g_icon_prefix || pk_sysdomain.get_img(i_lang, 'SCHEDULE_BED.CONF_TEMP', 'S')) icon_sch_status
              FROM schedule     s,
                   schedule     s1,
                   schedule_bed sb,
                   schedule_bed sb1,
                   bed          b,
                   sch_group    sg,
                   sch_group    sg1,
                   patient      p,
                   patient      p1,
                   room         r,
                   department   d,
                   institution  i
             WHERE s.id_schedule = sb.id_schedule
               AND sb.id_bed = b.id_bed
               AND s.id_schedule = sg.id_schedule
               AND p.id_patient = sg.id_patient
               AND b.id_room = r.id_room
               AND s.id_sch_event = g_inp_sch_event
               AND s.flg_status <> pk_schedule.g_status_canceled
               AND sb.flg_conflict = g_yes
               AND s1.id_schedule = sb1.id_schedule
               AND s1.id_schedule = sg1.id_schedule
               AND sg1.id_patient = p1.id_patient
               AND sb.id_bed = sb1.id_bed
               AND d.id_department = r.id_department
               AND d.id_institution = i.id_institution
               AND s1.flg_status <> pk_schedule.g_status_canceled
               AND s.dt_begin_tstz BETWEEN s1.dt_begin_tstz AND s1.dt_end_tstz
               AND s.id_schedule <> s1.id_schedule
               AND (s.dt_begin_tstz >= l_date OR
                   s.id_schedule IN (SELECT s2.id_schedule
                                        FROM schedule s2
                                        JOIN schedule_bed sb2
                                          ON sb2.id_schedule = s2.id_schedule
                                         AND s2.flg_status != pk_schedule.g_status_canceled
                                         AND trunc(l_date) BETWEEN s2.dt_begin_tstz AND s2.dt_end_tstz
                                      
                                      ))
            
            UNION ALL
            
            SELECT pk_date_utils.date_send_tsz(i_lang, tab.dt_begin, i_prof) dt_begin,
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, tab.dt_begin, 'Mon DD') AS start_date,
                   pk_date_utils.date_year_tsz(i_lang, tab.dt_begin, i_prof.institution, i_prof.software) AS start_date_year,
                   pk_date_utils.date_send_tsz(i_lang, tab.dt_end, i_prof) dt_end,
                   i.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) AS location,
                   d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) AS service,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name,
                   -- o paciente que provocou o conflito
                   tab.id_schedule AS id_schedule_ad,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p1.id_patient, NULL, NULL) photo_ad,
                   pk_patient.get_gender(i_lang, p1.gender) AS gender_ad,
                   pk_patient.get_pat_age(i_lang, p1.id_patient, i_prof) pat_age_ad,
                   pk_patient.get_pat_name(i_lang, i_prof, p1.id_patient, NULL) patient_name_ad,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p1.id_patient) pat_ad_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p1.id_patient) pat_ad_nd_icon,
                   
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, tab.dt_end, 'Mon DD') || ' ' ||
                   pk_date_utils.date_year_tsz(i_lang, tab.dt_end, i_prof.institution, i_prof.software) AS discharge_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, tab.dt_end, i_prof.institution, i_prof.software) AS discharges_hour,
                   -- o paciente que vai entrar
                   s.id_schedule,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, NULL, NULL) photo_ad,
                   pk_patient.get_gender(i_lang, p.gender) AS gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, NULL) patient_name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   
                   pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof) admission_total_date,
                   pk_date_utils.to_char_insttimezone(i_lang, i_prof, s.dt_begin_tstz, 'Mon DD') || ' ' ||
                   pk_date_utils.date_year_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) AS admission_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) AS admission_hour,
                   decode(sb.flg_temporary,
                          g_yes,
                          pk_schedule.g_icon_prefix || pk_sysdomain.get_img(i_lang, 'SCHEDULE_BED.CONF_TEMP', 'C'),
                          pk_schedule.g_icon_prefix || pk_sysdomain.get_img(i_lang, 'SCHEDULE_BED.CONF_TEMP', 'S')) icon_sch_status
              FROM TABLE(l_tab_allocs) tab
              JOIN patient p1
                ON p1.id_patient = tab.id_patient
              JOIN schedule s
                ON tab.id_schedule = s.id_schedule
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              JOIN patient p
                ON sg.id_patient = p.id_patient
              JOIN bed b
                ON tab.id_bed = b.id_bed
              JOIN room r
                ON b.id_room = r.id_room
              JOIN department d
                ON r.id_department = d.id_department
              JOIN institution i
                ON d.id_institution = i.id_institution
             ORDER BY dt_begin;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_conflicts);
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
    END get_conflicts;

    /**********************************************************************************************
    * This function returns the schedule begin date and patient of the next schedule.
    * - i_id_bed is not null and i_date is null -> returns the next scheduled dates
    * - i_id_bed is not null and i_date is not null -> returns the schedule in the given date if exists
    * - i_date is not null and i_id_bed id null -> returns all the bed appointment in the given date
    * - i_date is null and i_id_bed is null -> returns all the future bed appointments
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_bed                        Bed identiifcation
    * @param o_next_sch_dt                   Next schedule date
    * @param o_id_patient                    Patient id of the next schedule    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/15
    **********************************************************************************************/
    FUNCTION get_next_sch_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE DEFAULT NULL,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_data   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_NEXT_SCH_DATE';
        l_date      TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        l_date := trunc(current_timestamp, 'HH');
    
        g_error := 'OPEN CURSOR O_DATA';
        OPEN o_data FOR
            SELECT sb.id_bed,
                   s.dt_begin_tstz,
                   sg.id_patient,
                   s.id_episode,
                   s.id_prof_schedules,
                   i_prof.software     AS software,
                   i_prof.institution  AS institution,
                   s.id_schedule
              FROM schedule s
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
             WHERE s.flg_status != pk_schedule.g_status_canceled
               AND (i_id_bed IS NULL OR sb.id_bed = i_id_bed)
               AND ((i_date IS NULL AND s.dt_begin_tstz BETWEEN l_date AND l_date + INTERVAL '1' hour) OR
                   (i_date IS NOT NULL AND trunc(s.dt_begin_tstz) = trunc(i_date)))
             ORDER BY s.dt_begin_tstz;
    
        -- IMPORTANT NOTE: the query order by should not be changed. If some change is required it is necessary to check
        -- if it will affect the INPATIENT bed management
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_data);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_next_sch_date;

    /**********************************************************************************************
    * This function returns the schedule begin date and patient of the next schedule.
    * - i_id_bed is not null and i_date is null -> returns the next scheduled dates
    * - i_id_bed is not null and i_date is not null -> returns the schedule in the given date if exists
    * - i_date is not null and i_id_bed id null -> returns all the bed appointments in the given date
    * - i_date is not null and i_id_bed is null -> returns all the bed appointments which begin date is greater than i_date
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_bed                        Bed identiifcation
    * @param o_next_sch_dt                   Next schedule date
    * @param o_id_patient                    Patient id of the next schedule    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/15
    **********************************************************************************************/
    FUNCTION get_next_schedule_date
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE DEFAULT NULL,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_data   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_NEXT_SCH_DATE';
    BEGIN
    
        g_error := 'OPEN CURSOR O_DATA';
        OPEN o_data FOR
            SELECT sb.id_bed, s.dt_begin_tstz, sg.id_patient
              FROM schedule s
              JOIN schedule_bed sb
                ON s.id_schedule = sb.id_schedule
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              LEFT JOIN bmng_bed_ea bbe
                ON bbe.id_episode = s.id_episode
               AND bbe.id_bed = sb.id_bed
             WHERE s.flg_status != pk_schedule.g_status_canceled
               AND (i_id_bed IS NULL OR sb.id_bed = i_id_bed)
               AND (i_date IS NOT NULL AND trunc(s.dt_begin_tstz) >= trunc(i_date))
               AND (bbe.id_bmng_action IS NULL)
             ORDER BY s.dt_begin_tstz;
    
        -- IMPORTANT NOTE: the query order by should not be changed. If some change is required it is necessary to check
        -- if it will affect the INPATIENT bed management
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_data);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_next_schedule_date;

    /**********************************************************************************************
    * Calculate the nr of NCHS that are being used.    
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_department                 Department/Service identification
    * @param i_date                          Input date
    * @param o_avail_nchs                    Available NCHs    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/15
    **********************************************************************************************/
    FUNCTION calc_nchs_in_use
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_between   IN VARCHAR2,
        i_dep_nch       IN NUMBER,
        o_nchs          OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(30) := 'CALC_NCHS_IN_USE';
        l_episodes          table_number;
        l_episodes_alloc    table_number := table_number();
        l_ids_waiting_list  table_number;
        l_dts_begin         table_timestamp_tz;
        l_dts_end           table_timestamp_tz;
        l_pat_info          pk_types.cursor_type;
        l_patient           patient.id_patient%TYPE;
        l_department        department.id_department%TYPE;
        l_nch               NUMBER;
        l_patients_with_nch table_number := table_number();
    
        l_nchs_patients NUMBER := 0;
    
        l_def_nch_value sys_config.value%TYPE;
    
        l_allocations      pk_types.cursor_type;
        l_alloc_id_bed     bed.id_bed%TYPE;
        l_alloc_id_patient patient.id_patient%TYPE;
        l_alloc_dt_begin   TIMESTAMP WITH LOCAL TIME ZONE;
        l_alloc_dt_end     TIMESTAMP WITH LOCAL TIME ZONE;
        l_alloc_id         bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
        l_alloc_episode    bmng_allocation_bed.id_episode%TYPE;
        l_adm_time         NUMBER;
        l_admission_date   TIMESTAMP WITH LOCAL TIME ZONE;
    
        --
        l_id_patient          waiting_list.id_patient%TYPE;
        l_id_adm_indic        adm_request.id_adm_indication%TYPE;
        l_id_prof_dest        adm_request.id_dest_prof%TYPE;
        l_id_dest_inst        adm_request.id_dest_inst%TYPE;
        l_id_department       adm_request.id_department%TYPE;
        l_id_dcs              adm_request.id_dep_clin_serv%TYPE;
        l_id_room_type        adm_request.id_room_type%TYPE;
        l_id_pref_room        adm_request.id_pref_room%TYPE;
        l_id_adm_type         adm_request.id_admission_type%TYPE;
        l_flg_mix_nurs        adm_request.flg_mixed_nursing%TYPE;
        l_id_bed_type         adm_request.id_bed_type%TYPE;
        l_dt_admission        adm_request.dt_admission%TYPE;
        l_id_episode          adm_request.id_dest_episode%TYPE;
        l_exp_duration        adm_request.expected_duration%TYPE;
        l_id_external_request waiting_list.id_external_request%TYPE;
    
        --
        l_needed       NUMBER;
        l_id_nch_level NUMBER;
    
        l_beginday TIMESTAMP WITH LOCAL TIME ZONE;
        l_endday   TIMESTAMP WITH LOCAL TIME ZONE;
        l_day      TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_count_day       NUMBER := 1;
        l_bmng_flg_action bmng_action.flg_action%TYPE;
    BEGIN
    
        -- get config sch_admission_time
        g_error := 'GET ADMISSION TIME FOR THIS DEPARTMENT';
        BEGIN
            SELECT nvl(admission_time, 0)
              INTO l_adm_time
              FROM sch_inp_dep_time s
             WHERE s.id_department = i_id_department;
        EXCEPTION
            WHEN OTHERS THEN
                l_adm_time := 0;
        END;
    
        l_admission_date := i_start_date + numtodsinterval(l_adm_time, 'MINUTE');
    
        -- select the episode not allocated with appointment to the inputed date
        g_error := 'SELECT PATIENTS';
        SELECT s.id_episode, sb.id_waiting_list, s.dt_begin_tstz, s.dt_end_tstz
          BULK COLLECT
          INTO l_episodes, l_ids_waiting_list, l_dts_begin, l_dts_end
          FROM schedule s
          JOIN schedule_bed sb
            ON sb.id_schedule = s.id_schedule
          JOIN bed b
            ON sb.id_bed = b.id_bed
          JOIN room r
            ON b.id_room = r.id_room
          JOIN department d
            ON d.id_department = r.id_department
         WHERE s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
           AND s.flg_status <> pk_schedule.g_status_canceled
           AND d.id_department = i_id_department
           AND ((i_flg_between = pk_alert_constant.g_no AND s.dt_begin_tstz <= l_admission_date AND
               s.dt_end_tstz > l_admission_date
               
               ) OR (i_flg_between = pk_alert_constant.g_yes AND s.dt_begin_tstz < i_end_date AND
               s.dt_end_tstz > i_start_date))
           AND s.id_schedule NOT IN (SELECT sa.id_schedule
                                       FROM sch_allocation sa);
    
        -- calc the nchs of the scheduled patients based on the indication for admission
        IF (l_episodes IS NOT NULL AND l_episodes.exists(1) AND l_episodes(1) IS NOT NULL)
        THEN
            FOR idx IN l_episodes.first .. l_episodes.last
            LOOP
                IF NOT get_adm_request_data(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_wl               => l_ids_waiting_list(idx),
                                            i_unscheduled         => g_no,
                                            o_id_patient          => l_id_patient,
                                            o_id_adm_indic        => l_id_adm_indic,
                                            o_id_prof_dest        => l_id_prof_dest,
                                            o_id_dest_inst        => l_id_dest_inst,
                                            o_id_department       => l_id_department,
                                            o_id_dcs              => l_id_dcs,
                                            o_id_room_type        => l_id_room_type,
                                            o_id_pref_room        => l_id_pref_room,
                                            o_id_adm_type         => l_id_adm_type,
                                            o_flg_mix_nurs        => l_flg_mix_nurs,
                                            o_id_bed_type         => l_id_bed_type,
                                            o_dt_admission        => l_dt_admission,
                                            o_id_episode          => l_id_episode,
                                            o_exp_duration        => l_exp_duration,
                                            o_id_external_request => l_id_external_request,
                                            o_error               => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_beginday := l_dts_begin(idx);
                l_endday   := l_dts_end(idx);
            
                -- iterate all days within the period i_dt_begin -> i_dt_end.
                g_error := 'START LOOP';
                l_day   := l_beginday;
                WHILE l_day <= l_endday
                      AND l_day <> i_start_date
                LOOP
                    l_day       := l_day + INTERVAL '1' DAY;
                    l_count_day := l_count_day + 1;
                END LOOP;
            
                g_error := 'CALL get_needed_nchs';
                IF NOT pk_nch_pbl.get_nch_value(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_adm_indication => l_id_adm_indic,
                                                i_nr_day            => l_count_day,
                                                o_nch_value         => l_needed,
                                                o_id_nch_level      => l_id_nch_level,
                                                o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                l_nchs_patients := l_nchs_patients + l_needed;
            END LOOP;
        END IF;
    
        --add the alocations_nch
        --l_nchs_patients := l_nchs_patients + i_dep_nch;
    
        -- select the patients with alocation to the inputed date
        -- get_alocations to this day 
        g_error := 'CALL PK_BMNG_PBL.GET_DATE_ALLOCATIONS';
        IF NOT pk_bmng_pbl.get_date_allocations(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_department      => table_number(i_id_department),
                                                i_institution     => NULL,
                                                i_dt_begin        => l_admission_date,
                                                i_dt_end          => NULL,
                                                o_effective_alloc => l_allocations,
                                                o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- get the patients NCHs to the allocated patients
        LOOP
            FETCH l_allocations
                INTO l_alloc_id_bed,
                     l_alloc_id_patient,
                     l_alloc_dt_begin,
                     l_alloc_id,
                     l_alloc_dt_end,
                     l_alloc_episode,
                     l_bmng_flg_action;
            EXIT WHEN l_allocations%NOTFOUND;
            g_error := 'LOOP THROUTH l_allocations cursor: l_alloc_id_patient: ' || l_alloc_id_patient;
        
            IF (l_bmng_flg_action <> pk_bmng_constant.g_bmng_act_flg_bed_sta_r)
            THEN
                l_nchs_patients := l_nchs_patients +
                                   pk_nch_pbl.get_nch_total(i_lang, i_prof, l_alloc_episode, i_start_date);
            END IF;
            --l_episodes_alloc.EXTEND(1);
            --l_episodes_alloc(l_episodes_alloc.LAST) := l_alloc_episode;        
        END LOOP;
    
        o_nchs := l_nchs_patients;
    
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
    END calc_nchs_in_use;

    /**********************************************************************************************
    * Calculate the available NCHs of a service in a given date/hour.    
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_department                 Department/Service identification
    * @param i_date                          Input date
    * @param o_avail_nchs                    Available NCHs    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/15
    **********************************************************************************************/
    FUNCTION calc_available_nchs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_total_nchs    IN NUMBER,
        i_dep_nch       NUMBER,
        o_avail_nchs    OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CALC_AVAILABLE_NCHS';
    
        l_nchs_in_use NUMBER;
    BEGIN
        -- calculate the number of NCHs that are being used
        g_error := 'CALL calc_nchs_in_use';
        IF NOT calc_nchs_in_use(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_id_department => i_id_department,
                                i_start_date    => i_start_date,
                                i_end_date      => i_end_date,
                                i_flg_between   => pk_alert_constant.g_no,
                                i_dep_nch       => i_dep_nch,
                                o_nchs          => l_nchs_in_use,
                                o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error      := 'SUBTRACT nchs_in_use to total_nchs';
        o_avail_nchs := i_total_nchs - l_nchs_in_use;
    
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
    END calc_available_nchs;

    /**********************************************************************************************
    * Calculate the available NCHs of a service in a given date/hour.    
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_department                 Department/Service identification
    * @param i_date                          Input date
    * @param o_avail_nchs                    Available NCHs    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/15
    **********************************************************************************************/
    FUNCTION calc_available_nchs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE DEFAULT NULL,
        i_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_avail_nchs    OUT NUMBER,
        o_total_nchs    OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CALC_AVAILABLE_NCHS';
    
        l_dep_info    pk_types.cursor_type;
        l_department  department.id_department%TYPE;
        l_blocked     NUMBER;
        l_dep_nch     NUMBER;
        l_nchs_in_use NUMBER;
    BEGIN
        g_error := 'CALL pk_bmng_pbl.get_total_department_info';
        IF NOT pk_bmng_pbl.get_total_department_info(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_department  => table_number(i_id_department),
                                                     i_institution => NULL,
                                                     i_dt_request  => trunc(i_start_date),
                                                     o_dep_info    => l_dep_info,
                                                     o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH l_dep_info';
        FETCH l_dep_info
            INTO l_department, l_blocked, l_dep_nch, o_total_nchs;
        CLOSE l_dep_info;
    
        IF (o_total_nchs IS NOT NULL)
        THEN
            g_error := 'CALL CALC_AVAILABLE_NCHSs';
            IF NOT calc_available_nchs(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_id_department => i_id_department,
                                       i_start_date    => i_start_date,
                                       i_end_date      => i_end_date,
                                       i_total_nchs    => o_total_nchs,
                                       i_dep_nch       => l_dep_nch,
                                       o_avail_nchs    => o_avail_nchs,
                                       o_error         => o_error)
            THEN
                RETURN FALSE;
            END IF;
            -- calculate the number of NCHs that are being used
            /*g_error := 'CALL calc_nchs_in_use';
            IF NOT calc_nchs_in_use(i_lang          => i_lang,
                                    i_prof          => i_prof,
                                    i_id_department => i_id_department,
                                    i_start_date    => i_start_date,
                                    i_end_date      => i_end_date,
                                    i_flg_between   => pk_alert_constant.g_no,
                                    i_dep_nch       => l_dep_nch,
                                    o_nchs          => l_nchs_in_use,
                                    o_error         => o_error)
            THEN
                RETURN FALSE;
            END IF;
            
            g_error      := 'SUBTRACT nchs_in_use to total_nchs';
            o_avail_nchs := o_total_nchs - l_nchs_in_use;*/
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
    END calc_available_nchs;

    /**********************************************************************************************
    * Calculate the service capacity. 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_department                 Department/Service identification
    * @param i_date                          Input date
    * @param o_avail_nchs                    Available NCHs    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/21
    **********************************************************************************************/
    FUNCTION calc_nchs_capacity
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_total_nch  IN NUMBER,
        i_avail_nch  IN NUMBER,
        i_needed_nch IN NUMBER DEFAULT NULL,
        o_capacity   OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CALC_NCH_CAPACITY';
        l_capacity  DEC(12, 2);
    BEGIN
        g_error := 'CALC CAPACITY';
    
        IF (i_needed_nch IS NULL)
        THEN
            l_capacity := (i_avail_nch / i_total_nch) * 100;
        ELSE
            l_capacity := ((i_total_nch + (i_needed_nch - i_avail_nch)) * 100) / i_total_nch;
        END IF;
    
        o_capacity := l_capacity;
    
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
    END calc_nchs_capacity;

    /**********************************************************************************************
    * Return the list of schedules that begins in a period of time. 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_start_allocation              Interval begin date
    * @param i_end_allocation                Interval end date
    * @param o_schs_conflict                 Table number with the resulted id_schedules    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/29
    **********************************************************************************************/
    FUNCTION verify_conflict_sch_allocation
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_start_allocation IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_allocation   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_bed           IN schedule_bed.id_bed%TYPE,
        i_sch_begin_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_schs_conflict    OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'verify_conflict_sch_allocation';
    
    BEGIN
        g_error := 'CALC CAPACITY';
    
        SELECT s.id_schedule
          BULK COLLECT
          INTO o_schs_conflict
          FROM schedule s
          JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE ((s.dt_begin_tstz BETWEEN i_start_allocation AND i_end_allocation) OR
               (s.dt_end_tstz BETWEEN i_start_allocation AND i_end_allocation))
           AND s.flg_status != pk_schedule.g_sched_status_cancelled
           AND sb.id_bed = i_id_bed
           AND s.dt_end_tstz >= i_sch_begin_date;
    
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
    END verify_conflict_sch_allocation;

    /**********************************************************************************************
    * Returns the id_bed of a schedule. 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule identifier
    * @param o_id_bed                        Bed identifier    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_schedule_bed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_id_bed      OUT schedule_bed.id_bed%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCHEDULE_BED';
    BEGIN
        g_error := 'SELECT ID_BED';
    
        SELECT sb.id_bed
          INTO o_id_bed
          FROM schedule s
          JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE s.id_schedule = i_id_schedule
           AND s.flg_status <> pk_schedule.g_status_canceled;
    
        RETURN TRUE;
    
    EXCEPTION
        /*WHEN no_data_found THEN
        o_id_bed := NULL;
        RETURN TRUE;*/
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
    END get_schedule_bed;

    /**********************************************************************************************
    * Returns the id_bed of a schedule. 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_epis                       Episode ID.
    * @param o_id_dep                        Department Id    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.7.5
    * @since                                 2009/12/10
    **********************************************************************************************/
    FUNCTION get_schedule_bed_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_id_dep  OUT department.id_department%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCHEDULE_BED_SERVICE';
    BEGIN
        g_error := 'SELECT ID_BED';
    
        SELECT r.id_department
          INTO o_id_dep
          FROM schedule s
         INNER JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         INNER JOIN bed b
            ON b.id_bed = sb.id_bed
         INNER JOIN room r
            ON r.id_room = b.id_room
         WHERE s.id_schedule = pk_schedule_inp.get_schedule_id(i_lang, i_prof, i_id_epis)
           AND s.flg_status <> pk_schedule.g_status_canceled;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_id_dep := NULL;
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
            RETURN FALSE;
    END get_schedule_bed_service;

    /**********************************************************************************************
    * API - insert one row on sch_consult_vac_oris_slot table
    *
    * @param i_id_sch_allocation             sch_allocation ID
    * @param i_id_schedule                   schedule ID
    * @param i_id_bmng_allocation_bed        bmng_allocation_bed ID    
    * @param o_id_sch_allocation             inserted sch_allocation id
    * @param o_error                         descripton error   
    *
    * @return                                success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.5
    * @since                                 2009/08/26
    **********************************************************************************************/
    FUNCTION ins_sch_allocation
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_schedule            IN sch_allocation.id_schedule%TYPE,
        i_id_bmng_allocation_bed IN sch_allocation.id_bmng_allocation_bed%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'INS_SCH_ALLOCATION';
    BEGIN
        g_error := 'INSERT INTO SCH_ALLOCATION';
        INSERT INTO sch_allocation
            (id_schedule, id_bmng_allocation_bed)
        VALUES
            (i_id_schedule, i_id_bmng_allocation_bed);
    
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
        
    END ins_sch_allocation;

    /**********************************************************************************************
    * API - Delete record from SCH_ALLOCATION table
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule ID
    * @param o_error                         error object
    *
    * @return                                success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009-10-20
    **********************************************************************************************/
    FUNCTION del_sch_allocation
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_schedule            IN sch_allocation.id_schedule%TYPE,
        i_id_bmng_allocation_bed IN sch_allocation.id_bmng_allocation_bed%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'DEL_SCH_ALLOCATION';
    BEGIN
        g_error := 'DELETE FROM SCH_ALLOCATION';
    
        DELETE sch_allocation
         WHERE id_schedule = i_id_schedule
           AND id_bmng_allocation_bed = i_id_bmng_allocation_bed;
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_sch_allocation;

    /**********************************************************************************************
    * Returns the bed scheduled to an admission episode 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier    
    * @param o_id_bed                        Bed identifier    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/15
    **********************************************************************************************/
    FUNCTION get_sch_bed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_id_bed     OUT bed.id_bed%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR O_DATA';
        SELECT sb.id_bed
          INTO o_id_bed
          FROM schedule s
          JOIN schedule_bed sb
            ON s.id_schedule = sb.id_schedule
         WHERE s.id_episode = i_id_episode
           AND s.flg_status <> pk_schedule.g_status_canceled;
    
        RETURN TRUE;
    
    EXCEPTION
        /*WHEN no_data_found THEN
        o_id_bed := NULL;
        RETURN TRUE;*/
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCH_BED',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_sch_bed;

    FUNCTION get_schedule_dcs
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN dep_clin_serv.id_dep_clin_serv%TYPE IS
        l_dcs dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
        g_error := 'OPEN CURSOR O_DATA';
        SELECT s.id_dcs_requested
          INTO l_dcs
          FROM schedule s
         WHERE s.id_episode = i_epis
           AND s.flg_status <> pk_schedule.g_status_canceled;
    
        RETURN l_dcs;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_schedule_dcs;

    /**********************************************************************************************
    * Returns the id schedule associated to an admission episode 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/20
    **********************************************************************************************/
    FUNCTION get_schedule_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN schedule.id_schedule%TYPE IS
        l_id_schedule schedule.id_schedule%TYPE := NULL;
        l_error       t_error_out;
    BEGIN
        BEGIN
            g_error := 'GET ID_SCHEDULE; i_id_episode: ' || i_id_episode;
        
            SELECT id_schedule
              INTO l_id_schedule
              FROM (SELECT s.*, row_number() over(PARTITION BY s.id_episode ORDER BY s.dt_schedule_tstz DESC) rn
                      FROM schedule s
                     WHERE s.id_episode = i_id_episode
                       AND s.flg_status <> pk_schedule.g_status_canceled
                       AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp)
             WHERE rn = 1;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_schedule := NULL;
            
        END;
    
        RETURN l_id_schedule;
    
    END get_schedule_id;

    /**********************************************************************************************
    * Returns the id schedule associated to an admission episode 
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/20
    **********************************************************************************************/
    FUNCTION get_last_schedule_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN schedule.dt_begin_tstz%TYPE,
        i_dt_end     IN schedule.dt_end_tstz%TYPE
    ) RETURN schedule.id_schedule%TYPE IS
        l_id_schedule schedule.id_schedule%TYPE := NULL;
        l_error       t_error_out;
    BEGIN
        BEGIN
            g_error := 'GET ID_SCHEDULE; i_id_episode: ' || i_id_episode;
        
            SELECT id_schedule
              INTO l_id_schedule
              FROM (SELECT s.*,
                           row_number() over(PARTITION BY s.id_episode ORDER BY flg_status, s.dt_schedule_tstz DESC) rn
                      FROM schedule s
                     WHERE s.id_episode = i_id_episode
                       AND s.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
                       AND s.dt_begin_tstz >= i_dt_begin
                       AND s.dt_begin_tstz < i_dt_end)
             WHERE rn = 1;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_schedule := NULL;
            
        END;
    
        RETURN l_id_schedule;
    
    END get_last_schedule_id;

    /**********************************************************************************************
    * Returns the schedule status associated to an episode
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/23
    **********************************************************************************************/
    FUNCTION get_schedule_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN schedule.flg_status%TYPE IS
        l_flg_status schedule.flg_status%TYPE := NULL;
        l_error      t_error_out;
    BEGIN
        BEGIN
            g_error := 'GET SCHEDULE status; i_id_episode: ' || i_id_episode;
        
            SELECT flg_status
              INTO l_flg_status
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule;
        EXCEPTION
            WHEN OTHERS THEN
                l_flg_status := NULL;
            
        END;
    
        RETURN l_flg_status;
    
    END get_schedule_status;

    /**********************************************************************************************
    * Returns the id professional that cancelled the schedule.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/27
    **********************************************************************************************/
    FUNCTION get_schedule_cancel_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN schedule.id_prof_cancel%TYPE IS
        l_id_prof_cancel schedule.id_prof_cancel%TYPE := NULL;
    BEGIN
        BEGIN
            g_error := 'GET SCHEDULE status; i_id_episode: ' || i_id_episode;
        
            SELECT id_prof_cancel
              INTO l_id_prof_cancel
              FROM schedule s
             WHERE s.id_schedule = i_id_schedule;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_prof_cancel := NULL;
            
        END;
    
        RETURN l_id_prof_cancel;
    
    END get_schedule_cancel_prof;

    /**********************************************************************************************
    * Checks if a given sch cancel reason exists.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_episode                    Episode identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/10/27
    **********************************************************************************************/
    FUNCTION check_cancel_reason
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1) := pk_alert_constant.g_no;
    BEGIN
        BEGIN
            g_error := 'GET CANCEL reason with id_sch_cancel_reason: ' || i_id_cancel_reason;
        
            SELECT pk_alert_constant.g_yes
              INTO l_status
              FROM sch_cancel_reason scr
             WHERE scr.id_sch_cancel_reason = i_id_cancel_reason;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_status := pk_alert_constant.g_no;
            
        END;
    
        RETURN l_status;
    
    END check_cancel_reason;

    /**********************************************************************************************
    * This function returns the schedule begin date and patient of the next schedule.
    * - i_id_bed is not null and i_date is null -> returns the next scheduled dates
    * - i_id_bed is not null and i_date is not null -> returns the schedule in the given date if exists
    * - i_date is not null and i_id_bed id null -> returns all the bed appointments in the given date
    * - i_date is not null and i_id_bed is null -> returns all the bed appointments which begin date is greater than i_date
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_bed                        Bed identification
    * @param i_date                          Date of the allocation
    
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.7.4
    * @since                                 2009/11/30
    **********************************************************************************************/
    FUNCTION get_conflict_sch_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_bed       IN bed.id_bed%TYPE,
        i_epis         IN episode.id_episode%TYPE,
        i_date         IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_has_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_CONFLICT_SCH_DATE';
    BEGIN
    
        g_error := 'OPEN CURSOR O_DATA';
        SELECT nvl(data.res, pk_alert_constant.g_no)
          INTO o_has_conflict
          FROM (SELECT pk_alert_constant.g_yes res
                  FROM schedule s
                  JOIN schedule_bed sb
                    ON s.id_schedule = sb.id_schedule
                  JOIN sch_group sg
                    ON s.id_schedule = sg.id_schedule
                  LEFT JOIN bmng_bed_ea bbeo
                    ON bbeo.id_episode = s.id_episode
                   AND bbeo.id_bed = sb.id_bed
                 WHERE s.flg_status != pk_schedule.g_status_canceled
                   AND sb.id_bed = i_id_bed
                   AND ((i_date IS NOT NULL AND
                       (trunc(s.dt_begin_tstz) <= trunc(i_date) AND trunc(s.dt_end_tstz) >= trunc(i_date)))
                       --                       OR                       (bbe.id_bmng_action IS NOT NULL)
                       
                       )
                   AND bbeo.id_bmng_action IS NULL
                
                ) data
        
        ;
    
        -- IMPORTANT NOTE: the query order by should not be changed. If some change is required it is necessary to check
        -- if it will affect the INPATIENT bed management
    
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
    END get_conflict_sch_date;

    /**********************************************************************************************
    * Check if the given id_schedule was rescheduled.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_id_schedule                   Schedule identifier        
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.1
    * @since                                 28-Jun-2011
    **********************************************************************************************/
    FUNCTION check_reschedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_rescheduled VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        BEGIN
            g_error := 'CHECK RESCHEDULE; i_id_schedule: ' || i_id_schedule;
        
            SELECT pk_alert_constant.g_yes
              INTO l_rescheduled
              FROM schedule s
             WHERE s.id_schedule_ref = i_id_schedule
               AND rownum = 1;
        
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
            
        END;
    
        RETURN l_rescheduled;
    
    END check_reschedule;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_inp;
/
