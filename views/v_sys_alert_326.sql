CREATE OR REPLACE VIEW v_sys_alert_326 AS
WITH aux AS
 (SELECT xint.id_sys_alert,
         xint.sys_lprof,
         xint.sys_lprof_i,
         xint.sys_id_prof,
         xint.sys_institution,
         xint.sys_software,
         xint.sys_lang,
         xint.sys_hand_off_type,
         pk_message.get_message(xint.sys_lang, 'V_ALERT_M326') sys_msg_alert_v00,
         pk_message.get_message(xint.sys_lang, 'ALERT_LIST_T003') sys_msg_alert_list_t003,
         pk_alerts.get_alerts_shortcut(xint.sys_lprof, xint.id_sys_alert) sys_id_shortcut,
         pk_date_utils.trunc_insttimezone(xint.sys_lprof_i, current_timestamp, NULL) sys_dt_current,
         pk_hhc_core.is_coordinator(xint.sys_lang, xint.sys_lprof) sys_is_coordinator,
         'I' sys_hhc_rejected,
         'F' sys_hhc_closed,
         'C' sys_hhc_cancelled,
         'D' sys_hhc_discontinued,
         pk_alerts.get_config_flg_read(xint.sys_lang, xint.sys_lprof, xint.id_sys_alert, NULL) sys_config_flg_read
    FROM (SELECT 326 id_sys_alert,
                 profissional(NULL, alert_context('i_institution'), NULL) sys_lprof_i,
                 profissional(alert_context('i_prof'), alert_context('i_institution'), alert_context('i_software')) sys_lprof,
                 alert_context('i_prof') sys_id_prof,
                 alert_context('i_institution') sys_institution,
                 alert_context('i_software') sys_software,
                 alert_context('i_lang') sys_lang,
                 alert_context('l_hand_off_type') sys_hand_off_type
            FROM dual) xint)
SELECT /*+ opt_param('_optimizer_use_feedback', 'false') */
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
 decode(aux.sys_software, 312, eh.id_epis_hhc, e.id_episode) id_episode,
 eh.id_epis_hhc,
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
 pk_hand_off_api.get_resp_icons(aux.sys_lang, aux.sys_lprof, e.id_episode, aux.sys_hand_off_type) resp_icons,
 sae.id_prof_order,
 v.id_patient
  FROM sys_alert_event sae
  JOIN aux
    ON aux.id_sys_alert = sae.id_sys_alert
  JOIN episode e
    ON e.id_episode = sae.id_episode
  JOIN epis_info ei
    ON e.id_episode = ei.id_episode
  JOIN epis_hhc_req eh
    ON eh.id_episode = e.id_episode
  JOIN visit v
    ON e.id_visit = v.id_visit
  JOIN patient p
    ON p.id_patient = v.id_patient
  LEFT JOIN room r
    ON r.id_room = ei.id_room
 WHERE sae.id_sys_alert = 326
   AND sae.id_institution = aux.sys_institution
   AND sae.id_record = eh.id_epis_hhc_req
   AND eh.flg_status NOT IN (sys_hhc_rejected, sys_hhc_closed, sys_hhc_cancelled, sys_hhc_discontinued)
   AND ((aux.sys_is_coordinator = 'Y') OR (pk_hhc_core.get_id_prof_request(eh.id_epis_hhc_req) = aux.sys_id_prof))
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = sae.id_sys_alert_event
           AND sar.id_professional = aux.sys_id_prof
           AND aux.sys_config_flg_read = 'N')
   AND pk_alerts.check_if_alert_expired(aux.sys_lprof, sae.dt_creation, sae.id_sys_alert) > 0;
