/*-- Last Change Revision: $Rev: 2027102 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_viewer IS

    FUNCTION get_wline_data
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_epis        OUT pk_types.cursor_type,
        o_total_epis  OUT NUMBER,
        o_department  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_triage sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WLINE_VIEWER_T003');
        l_msg_obs    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WLINE_VIEWER_T004');
    
        l_triage_type NUMBER;
        l_num_utentes NUMBER;
    
    BEGIN
    
        g_error       := 'GET TRIAGE TYPE';
        l_triage_type := pk_edis_triage.get_triage_type_by_dep(i_lang       => i_lang,
                                                               i_prof       => profissional(NULL, i_institution, NULL),
                                                               i_department => i_department);
    
        g_error       := 'GET EDIS_VIEWER_NUM_UT';
        l_num_utentes := to_number(pk_sysconfig.get_config('EDIS_VIEWER_NUM_UT',
                                                           i_institution,
                                                           pk_alert_constant.g_soft_edis));
    
        g_error := 'OPEN O_EPIS';
        OPEN o_epis FOR
        --episódios não triados
        --contar o nr de episódios não triados, e ver o
        --tempo que demorou aos episódios triados a serem triados
            SELECT tc.color,
                   tc.color_text,
                   tc.rank,
                   nvl(num_epis.num_epis_total, 0) num_epis_total,
                   nvl(num_epis.num_epis_total, 0) num_epis_not_obs,
                   REPLACE(l_msg_triage, '@1', nvl(num_epis.num_epis_total, 0)) desc_num_epis_not_obs,
                   (SELECT pk_edis_viewer.get_format_wait_time(i_lang, AVG(time_diff) * 24 * 60)
                      FROM (SELECT pk_date_utils.get_timestamp_diff(et.dt_end_tstz, epis.dt_begin_tstz_e) time_diff
                              FROM v_episode_act_pend epis, epis_triage et, triage_color tc
                             WHERE epis.id_software = pk_alert_constant.g_soft_edis
                                  --seleccionar ultima triagem
                               AND epis.id_institution = i_institution
                               AND et.id_episode = epis.id_episode
                               AND et.dt_begin_tstz > epis.dt_begin_tstz_e --bd de dsv !
                               AND EXISTS
                             (SELECT 0
                                      FROM dep_clin_serv d
                                     WHERE d.id_department = i_department
                                       AND d.id_dep_clin_serv = epis.id_dep_clin_serv)
                               AND et.dt_end_tstz = (SELECT MIN(etr.dt_end_tstz)
                                                       FROM epis_triage etr
                                                      WHERE etr.id_episode = epis.id_episode)
                               AND et.id_triage_color = tc.id_triage_color
                               AND tc.id_triage_type = l_triage_type
                               AND tc.flg_type NOT IN (pk_alert_constant.g_triage_color_flgtype_noaval,
                                                       pk_alert_constant.g_triage_color_flgtype_nocolor,
                                                       pk_alert_constant.g_triage_color_flgtype_white)
                               AND tc.flg_available = pk_alert_constant.g_available
                             ORDER BY dt_end_tstz DESC)
                     WHERE rownum <= l_num_utentes) minutes_to_wait
              FROM triage_color tc,
                   (SELECT COUNT(epis.id_episode) num_epis_total
                      FROM v_episode_act epis
                     WHERE epis.id_software = pk_alert_constant.g_soft_edis
                       AND NOT EXISTS (SELECT 0
                              FROM triage_color tc
                             WHERE epis.id_triage_color = tc.id_triage_color
                               AND tc.id_triage_type = l_triage_type
                               AND tc.flg_type NOT IN
                                   (pk_alert_constant.g_triage_color_flgtype_noaval,
                                    pk_alert_constant.g_triage_color_flgtype_nocolor)
                               AND tc.flg_available = pk_alert_constant.g_available)
                       AND epis.id_institution = i_institution
                       AND EXISTS (SELECT 0
                              FROM dep_clin_serv dcs
                             WHERE dcs.id_department = i_department
                               AND dcs.id_dep_clin_serv = epis.id_dep_clin_serv)) num_epis
             WHERE tc.id_triage_type = l_triage_type
               AND tc.flg_type = pk_alert_constant.g_triage_color_flgtype_nocolor
               AND tc.flg_available = pk_alert_constant.g_available
            UNION ALL
            --episódios triados
            --contar todos os episódios activos triados, e para os que tem uma primeira
            --observação, calcula-se o tempo passado desde que foram triados
            SELECT tc.color,
                   tc.color_text,
                   tc.rank,
                   nvl(num_epis.num_epis_total, 0) num_epis_total,
                   nvl(num_epis.num_epis_not_obs, 0) num_epis_not_obs,
                   REPLACE(l_msg_obs, '@1', nvl(num_epis.num_epis_not_obs, 0)) desc_num_epis_not_obs,
                   (SELECT pk_edis_viewer.get_format_wait_time(i_lang, AVG(t.time_diff) * 24 * 60)
                      FROM (SELECT decode(epis.id_triage_color,
                                          g_triage_color_red,
                                          0,
                                          pk_date_utils.get_timestamp_diff(epis.dt_first_obs_tstz, et.dt_end_tstz)) time_diff,
                                   epis.id_triage_color
                              FROM v_episode_act_pend epis, epis_triage et
                             WHERE epis.id_software = pk_alert_constant.g_soft_edis
                               AND epis.id_institution = i_institution
                               AND et.id_episode = epis.id_episode
                               AND epis.dt_first_obs_tstz IS NOT NULL
                               AND epis.dt_first_obs_tstz > et.dt_end_tstz --bd de dsv !
                               AND EXISTS
                             (SELECT 0
                                      FROM dep_clin_serv dcs
                                     WHERE dcs.id_department = i_department
                                       AND dcs.id_dep_clin_serv = epis.id_dep_clin_serv)
                               AND et.dt_end_tstz = (SELECT MIN(etr.dt_end_tstz)
                                                       FROM epis_triage etr
                                                      WHERE etr.id_episode = epis.id_episode)
                             ORDER BY dt_first_obs_tstz DESC) t
                     WHERE rownum <= l_num_utentes
                       AND t.id_triage_color = tc.id_triage_color) minutes_to_wait
              FROM triage_color tc,
                   (SELECT epis.id_triage_color,
                           COUNT(epis.id_episode) num_epis_total,
                           COUNT(decode(epis.dt_first_obs_tstz, NULL, 1, NULL)) num_epis_not_obs
                      FROM v_episode_act epis
                     WHERE epis.id_software = pk_alert_constant.g_soft_edis
                       AND epis.id_institution = i_institution
                       AND EXISTS (SELECT 0
                              FROM dep_clin_serv dcs
                             WHERE dcs.id_department = i_department
                               AND dcs.id_dep_clin_serv = epis.id_dep_clin_serv)
                     GROUP BY epis.id_triage_color) num_epis
             WHERE tc.id_triage_type = l_triage_type
               AND tc.flg_type NOT IN (pk_alert_constant.g_triage_color_flgtype_noaval,
                                       pk_alert_constant.g_triage_color_flgtype_nocolor,
                                       pk_alert_constant.g_triage_color_flgtype_white)
               AND tc.flg_available = pk_alert_constant.g_available
               AND tc.id_triage_color = num_epis.id_triage_color(+)
             ORDER BY rank;
    
        g_error := 'GET O_TOTAL_EPIS';
        SELECT COUNT(0)
          INTO o_total_epis
          FROM v_episode_act epis
         WHERE epis.id_software = pk_alert_constant.g_soft_edis
           AND epis.id_institution = i_institution
           AND NOT EXISTS (SELECT 0
                  FROM triage_color tc
                 WHERE tc.id_triage_color = epis.id_triage_color
                   AND tc.flg_type IN (pk_alert_constant.g_triage_color_flgtype_noaval,
                                       pk_alert_constant.g_triage_color_flgtype_white)
                   AND tc.id_triage_type = l_triage_type
                   AND tc.flg_available = pk_alert_constant.g_available)
           AND EXISTS (SELECT 0
                  FROM dep_clin_serv dcs
                 WHERE dcs.id_department = i_department
                   AND dcs.id_dep_clin_serv = epis.id_dep_clin_serv);
    
        g_error := 'GET O_DEPARTMENT';
        SELECT pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || i_department) desc_department
          INTO o_department
          FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WLINE_DATA',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_epis);
        
            RETURN FALSE;
    END get_wline_data;

    FUNCTION get_format_wait_time
    (
        i_lang    IN language.id_language%TYPE,
        i_minutes IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_hours   PLS_INTEGER;
        l_minutes PLS_INTEGER;
    
    BEGIN
    
        IF i_minutes IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        IF i_minutes < 0
        THEN
            l_minutes := 0;
        ELSE
            l_minutes := i_minutes;
        END IF;
    
        l_hours   := floor(l_minutes / 60);
        l_minutes := floor(l_minutes - l_hours * 60);
    
        RETURN lpad(to_char(l_hours), 2, 0) || pk_message.get_message(i_lang, 'HOURS_SIGN') --
        || ' ' || lpad(to_char(l_minutes), 2, 0) || pk_message.get_message(i_lang, 'MINUTES_SIGN');
    
    END get_format_wait_time;

    FUNCTION get_config
    (
        i_code_cf     IN table_varchar,
        i_institution IN NUMBER,
        o_msg_cf      OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_sysconfig.get_config(i_code_cf   => i_code_cf,
                                       i_prof_inst => i_institution,
                                       i_prof_soft => pk_alert_constant.g_soft_edis,
                                       o_msg_cf    => o_msg_cf);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_config;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_edis_viewer;
/
