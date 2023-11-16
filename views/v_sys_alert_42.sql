CREATE OR REPLACE VIEW V_SYS_ALERT_42 AS
WITH aux AS
 (SELECT xint.id_sys_alert,
         --xint.flg_read,
         xint.sys_lprof,
         xint.sys_lprof_i,
         xint.sys_id_prof,
         xint.sys_institution,
         xint.sys_software,
         xint.sys_lang,
         xint.sys_hand_off_type,
         pk_sysconfig.get_config('ALERT_INTERVENTION_TIMEOUT2', xint.sys_institution, xint.sys_software) sys_cfg_intervention_timeout2,
         pk_date_utils.trunc_insttimezone(xint.sys_lprof_i, current_timestamp, NULL) sys_dt_current,
         pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(xint.sys_lprof_i, current_timestamp, NULL),
                                        -pk_sysconfig.get_config('ALERT_EXPIRE_TAKE',
                                                                 xint.sys_institution,
                                                                 xint.sys_software)) sys_diff_expire_take,
         pk_date_utils.add_days_to_tstz(current_timestamp,
                                        - (pk_sysconfig.get_config('ALERT_TAKE_TIMEOUT1',
                                                                  xint.sys_institution,
                                                                  xint.sys_software) / (24 * 60))) sys_dt_add_timeout_dayz,
         pk_message.get_message(xint.sys_lang, 'V_ALERT_M011') sys_msg_alert_v00,
         pk_message.get_message(xint.sys_lang, 'ALERT_LIST_T003') sys_msg_alert_list_t003,
         pk_alerts.get_alerts_shortcut(xint.sys_lprof, xint.id_sys_alert) sys_id_shortcut,
         pk_alerts.get_config_flg_read(xint.sys_lang, xint.sys_lprof, xint.id_sys_alert, NULL) sys_config_flg_read
    FROM (SELECT sa.id_sys_alert,
                 --sa.flg_read,
                 profissional(NULL, alert_context('i_institution'), NULL) sys_lprof_i,
                 profissional(alert_context('i_prof'), alert_context('i_institution'), alert_context('i_software')) sys_lprof,
                 alert_context('i_prof') sys_id_prof,
                 alert_context('i_institution') sys_institution,
                 alert_context('i_software') sys_software,
                 alert_context('i_lang') sys_lang,
                 alert_context('l_hand_off_type') sys_hand_off_type
            FROM sys_alert sa
           WHERE sa.id_sys_alert = 42) xint)
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 aux.sys_lprof,
 aux.sys_id_prof,
 aux.sys_institution,
 aux.sys_dt_current,
 NULL sys_cfg_expire_transfer,
 aux.sys_software,
 aux.sys_lang,
 aux.sys_hand_off_type,
 aux.sys_config_flg_read,
 aux.sys_msg_alert_v00,
 aux.sys_msg_alert_list_t003,
 aux.sys_dt_add_timeout_dayz,
 aux.sys_id_shortcut,
 e.id_episode,
 ei.id_schedule,
 e.dt_begin_tstz,
 ei.triage_rank_acuity,
 ei.dt_first_obs_tstz,
 ei.id_triage_color,
 ei.triage_acuity,
 e.id_patient,
 p.gender,
 r.desc_room_abbreviation,
 r.code_abbreviation,
 r.desc_room,
 r.code_room,
 sae.id_sys_alert_event,
 sae.id_institution,
 sae.id_professional,
 sae.dt_record,
 sae.replace1,
 sae.replace2,
 sae.id_sys_alert,
 sae.id_record,
 sae.id_prof_order
  FROM sys_alert_event sae
  JOIN aux
    ON aux.id_sys_alert = sae.id_sys_alert
  JOIN episode e
    ON e.id_episode = sae.id_episode
  JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  JOIN room r
    ON r.id_room = ei.id_room
  JOIN patient p
    ON p.id_patient = e.id_patient
 WHERE sae.id_sys_alert = 42
   AND sae.id_institution = aux.sys_institution
   AND sae.flg_visible = 'Y'
   AND sys_diff_expire_take < pk_date_utils.trunc_insttimezone(aux.sys_lprof_i, sae.dt_record, NULL)
   AND sae.dt_record < sys_dt_add_timeout_dayz
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = sae.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                             sae.id_sys_alert,
                                             NULL) = 'N')
   AND ((sae.id_clinical_service IS NOT NULL --Devolve o alerta para o prof que requitou ou todos os nao médicos do serviço do episódio
       AND (aux.sys_id_prof IN (SELECT DISTINCT pdcs.id_professional
                                    FROM dep_clin_serv dcs
                                    JOIN prof_dep_clin_serv pdcs
                                      ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                    JOIN prof_cat pc
                                      ON pc.id_professional = pdcs.id_professional
                                    JOIN category c
                                      ON c.id_category = pc.id_category
                                   WHERE dcs.id_clinical_service = sae.id_clinical_service
                                     AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                     AND pdcs.flg_status = 'S'
                                     AND pc.id_professional = pdcs.id_professional
                                     AND pc.id_institution = sae.id_institution
                                     AND c.id_category = pc.id_category
                                     AND c.flg_type != 'D') OR sae.id_professional = aux.sys_id_prof)) OR
       (sae.id_clinical_service IS NULL AND sae.id_professional = aux.sys_id_prof))
;
