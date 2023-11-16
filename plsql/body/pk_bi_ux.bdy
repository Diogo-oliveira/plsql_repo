/*-- Last Change Revision: $Rev: 2047907 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-10-20 14:27:07 +0100 (qui, 20 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_bi_ux IS

    --read spec for full comments
    FUNCTION get_adw_header_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_adw_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_reset_patient      CONSTANT PLS_INTEGER := -1;
        c_flg_ehr_effective  CONSTANT VARCHAR2(1) := 'N';
        c_flg_migration_test CONSTANT VARCHAR2(1) := 'T';
    
        l_breach_minutes        NUMBER;
        l_breach_hour           NUMBER;
        l_check_intake_time_cfg sys_config.desc_sys_config%TYPE;
    
    BEGIN
    
        -- 'Active patients' is the number of current EDIS active episodes.
    
        -- 'Total attendance' is the number of EDIS episodes that started this day. 
        -- The start of the episode is calculated form the arrival date (or the admission date if the arrival date is not known) 
    
        -- 'x hour breaches' is the number of EDIS episodes that exceeded a duration of x hours and that started the present day. 
        -- The duration of the episode is calculated with the start date of the episode and the final discharge 
        -- (or the current date if there is no final discharge) 
    
        -- 'LOS / Day" is the average duration of EDIS episodes that started the present day.
    
        l_breach_minutes := pk_edis_grid.get_los_breach(i_lang, i_prof);
        l_breach_hour    := (l_breach_minutes / 60) / 24;
    
        l_check_intake_time_cfg := pk_sysconfig.get_config('USE_INTAKE_TIME_TO_CALCULATE_LOS', i_prof);
    
        g_error := 'OPEN O_ADW_INFO';
        OPEN o_adw_info FOR
            SELECT i.id_institution id_institution,
                   nvl(pk_date_utils.get_elapsed_date_tsz(i_lang, current_timestamp - episode_time, ' '), '') episode_time,
                   nvl(num_total_episodes, 0) sum_total_episodes,
                   nvl(actives.sum_active_episodes, 0) sum_active_episodes,
                   nvl(breaches.total, 0) breaches
              FROM institution i
              LEFT JOIN (SELECT e.id_institution,
                                SUM(CAST(coalesce(dis.dt_discharge_final_last, current_date) AS DATE) -
                                    CAST(coalesce(arrival.dt_arrival, e.dt_begin_tstz) AS DATE)) / COUNT(*) episode_time,
                                COUNT(*) num_total_episodes
                           FROM episode e
                           LEFT JOIN (SELECT coalesce(dis_last.dt_med, dis_last.dt_pend_active) dt_discharge_final_last,
                                            id_episode
                                       FROM (SELECT id_discharge, id_episode, dt_med, dt_admin, dt_pend_active, rank
                                               FROM (SELECT d.id_discharge,
                                                            d.id_episode,
                                                            d.dt_med_tstz dt_med,
                                                            d.dt_admin_tstz dt_admin,
                                                            d.dt_pend_active_tstz dt_pend_active,
                                                            rank() over(PARTITION BY d.id_episode ORDER BY d.dt_admin_tstz DESC, dt_med_tstz DESC NULLS LAST, id_discharge DESC) AS rank
                                                       FROM discharge d
                                                       JOIN episode e1
                                                         ON d.id_episode = e1.id_episode
                                                      WHERE d.flg_status = pk_alert_constant.g_active
                                                        AND e1.dt_begin_tstz >= trunc(current_date))
                                              WHERE rank = 1) dis_last) dis
                             ON (e.id_episode = dis.id_episode)
                           LEFT JOIN (SELECT id_episode, dt_register dt_arrival
                                       FROM (SELECT eitg.id_episode AS id_episode, eitg.dt_intake_time AS dt_register
                                               FROM (SELECT eit.id_episode,
                                                            eit.dt_intake_time,
                                                            rank() over(PARTITION BY eit.id_episode ORDER BY dt_register DESC) rank_
                                                       FROM epis_intake_time eit
                                                      WHERE eit.dt_intake_time >= trunc(current_date)) eitg
                                              WHERE rank_ = 1
                                                AND l_check_intake_time_cfg = pk_alert_constant.g_yes)) arrival
                             ON (arrival.id_episode = e.id_episode)
                          WHERE e.id_epis_type IN
                                (SELECT etsi.id_epis_type
                                   FROM epis_type_soft_inst etsi
                                  WHERE etsi.id_software = i_prof.software
                                    AND etsi.id_institution IN (i_prof.institution, 0))
                            AND e.flg_migration != c_flg_migration_test
                            AND e.flg_ehr = c_flg_ehr_effective
                            AND e.id_patient != c_reset_patient
                            AND e.flg_status != pk_alert_constant.g_cancelled
                            AND (coalesce(arrival.dt_arrival, e.dt_begin_tstz)) >= trunc(current_date)
                          GROUP BY id_institution) total
                ON (total.id_institution = i.id_institution)
              LEFT JOIN (SELECT id_institution, COUNT(*) sum_active_episodes
                           FROM episode e
                          WHERE e.id_epis_type IN
                                (SELECT etsi.id_epis_type
                                   FROM epis_type_soft_inst etsi
                                  WHERE etsi.id_software = i_prof.software
                                    AND etsi.id_institution IN (i_prof.institution, 0))
                            AND e.flg_migration != c_flg_migration_test
                            AND e.flg_ehr = c_flg_ehr_effective
                            AND e.id_patient != c_reset_patient
                            AND flg_status = pk_alert_constant.g_active
                          GROUP BY id_institution) actives
                ON (actives.id_institution = i.id_institution)
              LEFT JOIN (SELECT id_institution, COUNT(*) total
                           FROM (SELECT e.id_institution, e.id_episode
                                   FROM episode e
                                   LEFT JOIN (SELECT coalesce(dis_last.dt_med, dis_last.dt_pend_active) dt_discharge_final_last,
                                                    id_episode
                                               FROM (SELECT id_discharge,
                                                            id_episode,
                                                            dt_med,
                                                            dt_admin,
                                                            dt_pend_active,
                                                            rank
                                                       FROM (SELECT d.id_discharge,
                                                                    d.id_episode,
                                                                    d.dt_med_tstz dt_med,
                                                                    d.dt_admin_tstz dt_admin,
                                                                    d.dt_pend_active_tstz dt_pend_active,
                                                                    rank() over(PARTITION BY d.id_episode ORDER BY d.dt_admin_tstz DESC, dt_med_tstz DESC NULLS LAST, id_discharge DESC) AS rank
                                                               FROM discharge d
                                                               JOIN episode e1
                                                                 ON d.id_episode = e1.id_episode
                                                              WHERE d.flg_status = pk_alert_constant.g_active
                                                                AND e1.dt_begin_tstz >= trunc(current_date))
                                                      WHERE rank = 1) dis_last) dis
                                     ON (e.id_episode = dis.id_episode)
                                   LEFT JOIN (SELECT id_episode, dt_register dt_arrival
                                               FROM (SELECT eitg.id_episode     AS id_episode,
                                                            eitg.dt_intake_time AS dt_register
                                                       FROM (SELECT id_episode,
                                                                    eit.dt_intake_time,
                                                                    rank() over(PARTITION BY id_episode ORDER BY dt_register DESC) rank_
                                                               FROM epis_intake_time eit
                                                              WHERE eit.dt_intake_time >= trunc(current_date)) eitg
                                                      WHERE rank_ = 1
                                                        AND l_check_intake_time_cfg = pk_alert_constant.g_yes)) arrival
                                     ON (arrival.id_episode = e.id_episode)
                                  WHERE e.id_epis_type IN
                                        (SELECT etsi.id_epis_type
                                           FROM epis_type_soft_inst etsi
                                          WHERE etsi.id_software = i_prof.software
                                            AND etsi.id_institution IN (i_prof.institution, 0))
                                    AND e.flg_migration != c_flg_migration_test
                                    AND e.flg_ehr = c_flg_ehr_effective
                                    AND e.id_patient != c_reset_patient
                                    AND e.flg_status NOT IN (pk_alert_constant.g_cancelled, pk_alert_constant.g_inactive)
                                    AND NOT EXISTS (SELECT 1
                                           FROM discharge d
                                          WHERE d.id_episode = e.id_episode
                                            AND d.flg_status NOT IN
                                                (pk_discharge.g_disch_flg_status_cancel,
                                                 pk_discharge.g_disch_flg_status_reopen))
                                 --    AND (coalesce(arrival.dt_arrival, e.dt_begin_tstz)) >= trunc(current_date)
                                  HAVING
                                  SUM(CAST(coalesce(dis.dt_discharge_final_last, current_date) AS DATE) -
                                            CAST(coalesce(arrival.dt_arrival, e.dt_begin_tstz) AS DATE)) > l_breach_hour
                                  GROUP BY e.id_episode, e.id_institution)
                          GROUP BY id_institution) breaches
                ON (i.id_institution = breaches.id_institution)
             WHERE i.id_institution = i_prof.institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ADW_HEADER_INFO',
                                              o_error);
            pk_types.open_my_cursor(o_adw_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_adw_header_info;

    FUNCTION get_breach_label
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_label   OUT VARCHAR,
        o_tooltip OUT VARCHAR,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_breach_minutes NUMBER;
        l_breach_hour    NUMBER;
    
        l_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                        i_prof      => i_prof,
                                                                        i_code_mess => 'INFO_HOUR_BREACHES');
    
        l_tooltip sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                          i_prof      => i_prof,
                                                                          i_code_mess => 'INFO_HOUR_BREACHES_TOOLTIP');
    
    BEGIN
    
        l_breach_minutes := pk_edis_grid.get_los_breach(i_lang, i_prof);
        l_breach_hour    := (l_breach_minutes / 60);
    
        o_label   := REPLACE(l_label, '%1', l_breach_hour);
        o_tooltip := REPLACE(l_tooltip, '%1', l_breach_hour);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_BREACH_LABEL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_breach_label;

    FUNCTION get_presc_credits
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_label OUT VARCHAR2,
        o_value OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_credits NUMBER;
    BEGIN
        l_credits := pk_api_pfh_in.get_light_license_credits(i_lang => i_lang, i_prof => i_prof);
        IF l_credits IS NOT NULL
        THEN
            o_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PRESC_LIGHT_T001');
        
            o_value := l_credits;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PRESC_CREDITS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_presc_credits;

    FUNCTION get_presc_credits_avail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_available    OUT VARCHAR2,
        o_refresh_time OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_credits      NUMBER;
        l_refresh_time sys_config.id_sys_config%TYPE;
    BEGIN
        IF pk_tools.get_prof_profile_template(i_prof) = 136 /*PP Light profile template*/
        THEN
            o_available    := pk_alert_constant.g_yes;
            o_refresh_time := pk_sysconfig.get_config('REFRESH_TIME_CREDITS_INFO', i_prof);
        ELSE
            o_available := pk_alert_constant.g_no;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PRESC_CREDITS_AVAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_presc_credits_avail;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i);

END pk_bi_ux;
/
