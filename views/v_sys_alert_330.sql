CREATE OR REPLACE   VIEW V_SYS_ALERT_330 AS
WITH aux AS
 (SELECT xint.id_sys_alert,
         xint.sys_lprof,
         xint.sys_lprof_i,
         xint.sys_id_prof,
         xint.sys_institution,
         xint.sys_software,
         xint.sys_lang,
         xint.sys_hand_off_type,
         pk_message.get_message(xint.sys_lang, 'V_ALERT_M330') sys_msg_alert_v00,
         pk_message.get_message(xint.sys_lang, 'ALERT_LIST_T003') sys_msg_alert_list_t003,
         pk_alerts.get_alerts_shortcut(xint.sys_lprof, xint.id_sys_alert) sys_id_shortcut,
         pk_date_utils.trunc_insttimezone(xint.sys_lprof_i, current_timestamp, NULL) sys_dt_current,
         pk_alerts.get_config_flg_read(xint.sys_lang, xint.sys_lprof, xint.id_sys_alert, NULL) sys_config_flg_read
    FROM (SELECT 330 id_sys_alert,
                 profissional(NULL, alert_context('i_institution'), NULL) sys_lprof_i,
                 profissional(alert_context('i_prof'), alert_context('i_institution'), alert_context('i_software')) sys_lprof,
                 alert_context('i_prof') sys_id_prof,
                 alert_context('i_institution') sys_institution,
                 alert_context('i_software') sys_software,
                 alert_context('i_lang') sys_lang,
                 alert_context('l_hand_off_type') sys_hand_off_type
            FROM dual) xint)
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 aux.sys_lprof,
 aux.sys_id_prof,
 aux.sys_institution,
 aux.sys_software,
 aux.sys_lang,
 aux.sys_hand_off_type,
 aux.sys_config_flg_read,
 aux.sys_msg_alert_v00,
 aux.sys_msg_alert_list_t003,
 aux.sys_id_shortcut,
 e.id_episode,
 e.dt_begin_tstz,
 ei.id_schedule,
 ei.dt_first_obs_tstz,
 ei.id_triage_color,
 ei.triage_acuity,
 ei.triage_rank_acuity,
 p.gender,
 r.desc_room_abbreviation,
 r.code_abbreviation,
 r.desc_room,
 r.code_room,
 sae.dt_record,
 sae.id_record,
 sae.id_sys_alert,
 sae.id_sys_alert_event,
 sae.id_institution,
 sae.id_professional,
 sae.replace1,
 sae.replace2,
 sae.id_prof_order,
 v.id_patient
  FROM sys_alert_event sae
  JOIN aux
    ON aux.id_sys_alert = sae.id_sys_alert
  JOIN episode e
    ON e.id_episode = sae.id_episode
  LEFT JOIN episode ep
    ON ep.id_episode = e.id_prev_episode
  JOIN epis_info ei
    ON e.id_episode = ei.id_episode
  JOIN visit v
    ON e.id_visit = v.id_visit
  JOIN patient p
    ON p.id_patient = v.id_patient
  LEFT JOIN room r
    ON r.id_room = ei.id_room
 WHERE sae.id_sys_alert = 330
   AND (pk_hhc_core.is_coordinator(i_lang => aux.sys_lang, i_prof => aux.sys_lprof) = 'Y' OR
       pk_hhc_core.is_case_manager(i_lang => aux.sys_lang, i_prof => aux.sys_lprof) = 'Y')
   AND (EXISTS (SELECT 1
                  FROM epis_hhc_req ehr
                 WHERE ehr.id_episode = e.id_episode
                   AND ehr.id_prof_manager = aux.sys_id_prof) OR EXISTS
        (SELECT 1
           FROM v_hhc_visits vhv
           JOIN sch_resource sr
             ON sr.id_schedule = vhv.id_schedule
          WHERE vhv.id_prev_episode = e.id_episode
            AND sr.id_professional = aux.sys_id_prof) OR sae.id_professional = aux.sys_id_prof)
   AND sae.id_institution = aux.sys_institution
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = sae.id_sys_alert_event
           AND sar.id_professional = aux.sys_id_prof
           AND aux.sys_config_flg_read = 'N')
  and pk_alerts.check_if_alert_expired( i_prof => aux.sys_lprof
                    , i_dt_creation  => sae.dt_creation
                    , i_id_sys_alert => sae.id_sys_alert ) > 0  
		   ;
