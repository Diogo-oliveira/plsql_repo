CREATE OR REPLACE VIEW V_SYS_ALERT_335 AS
WITH aux_sql AS
 (SELECT xint.id_sys_alert,
         xint.sys_lprof,
         xint.sys_lprof_i,
         xint.sys_id_prof,
         xint.sys_institution,
         xint.sys_software,
         xint.sys_lang,
         xint.sys_hand_off_type,
         pk_alerts.get_alerts_shortcut(xint.sys_lprof, xint.id_sys_alert) sys_id_shortcut,
         pk_message.get_message(xint.sys_lang, 'BLOOD_PRODUCTS_T167') sys_msg_alert_bp_t167,
         pk_message.get_message(xint.sys_lang, 'ALERT_LIST_T003') sys_msg_alert_list_t003,
         pk_date_utils.trunc_insttimezone(xint.sys_lprof_i, current_timestamp, NULL) sys_dt_current
    FROM (SELECT 335 id_sys_alert,
                 profissional(NULL, alert_context('i_institution'), NULL) sys_lprof_i,
                 profissional(alert_context('i_prof'), alert_context('i_institution'), alert_context('i_software')) sys_lprof,
                 alert_context('i_prof') sys_id_prof,
                 alert_context('i_institution') sys_institution,
                 alert_context('i_software') sys_software,
                 alert_context('i_lang') sys_lang,
                 alert_context('l_hand_off_type') sys_hand_off_type
            FROM dual) xint)
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 sae.id_sys_alert_event id_sys_alert_det,
 sae.id_record id_reg,
 sae.id_episode,
 sae.id_institution,
 sae.id_professional id_prof,
 pk_date_utils.to_char_insttimezone(profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                                    sae.dt_record,
                                    'YYYYMMDDHH24MISS') dt_req,
 decode(nvl(instr(pk_date_utils.get_elapsed_sysdate_tsz(aux_sql.sys_lang, sae.dt_record), ':'), 0),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(aux_sql.sys_lang, sae.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(aux_sql.sys_lang, sae.dt_record) || ' ' || aux_sql.sys_msg_alert_list_t003) TIME,
 aux_sql.sys_msg_alert_bp_t167 || ' (' || pk_translation.get_translation(aux_sql.sys_lang, ht.code_hemo_type) || ')' message,
 ei.id_room,
 sae.id_patient,
 pk_patient.get_pat_name(aux_sql.sys_lang,
                         profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                         ei.id_patient,
                         ei.id_episode,
                         ei.id_schedule) name_pat,
 pk_adt.get_pat_non_disc_options(aux_sql.sys_lang,
                                 profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                                 ei.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(aux_sql.sys_lang,
                                    profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                                    ei.id_patient) pat_nd_icon,
 pk_patphoto.get_pat_photo(aux_sql.sys_lang,
                           profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                           ei.id_patient,
                           ei.id_episode,
                           ei.id_schedule) photo,
 p.gender,
 pk_patient.get_pat_age(aux_sql.sys_lang, p.dt_birth, p.age, aux_sql.sys_institution, aux_sql.sys_software) pat_age,
 (SELECT coalesce(r.desc_room_abbreviation,
                  pk_translation.get_translation(aux_sql.sys_lang, r.code_abbreviation),
                  r.desc_room,
                  pk_translation.get_translation(aux_sql.sys_lang, r.code_room))
    FROM room r
   WHERE ei.id_room = r.id_room) desc_room,
 (SELECT pk_date_utils.get_elapsed_sysdate_tsz(aux_sql.sys_lang, e.dt_begin_tstz)
    FROM episode e
   WHERE sae.id_episode = e.id_episode) date_send,
 pk_edis_grid.get_complaint_grid(aux_sql.sys_lang, aux_sql.sys_institution, aux_sql.sys_software, sae.id_episode) desc_epis_anamnesis,
 nvl(ei.triage_acuity, '0x787864') acuity,
 nvl(ei.triage_rank_acuity, 999) rank_acuity,
 NULL id_schedule,
 pk_alerts.get_alerts_shortcut(profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                               sae.id_sys_alert) id_sys_shortcut,
 sae.id_sys_alert_event id_reg_det,
 sae.id_sys_alert,
 pk_episode.get_epis_dt_first_obs(ei.id_episode, ei.dt_first_obs_tstz, NULL, 'Y') dt_first_obs_tstz,
 pk_fast_track.get_fast_track_icon(aux_sql.sys_lang,
                                   profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                                   ei.id_episode,
                                   NULL,
                                   ei.id_triage_color,
                                   NULL,
                                   vea.has_transfer) fast_track_icon,
 decode(ei.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
 'A' fast_track_status,
 pk_edis_triage.get_epis_esi_level(aux_sql.sys_lang,
                                   profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                                   ei.id_episode,
                                   ei.id_triage_color) esi_level,
 pk_patient.get_pat_name_to_sort(aux_sql.sys_lang,
                                 profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                                 p.id_patient,
                                 ei.id_episode) name_pat_sort,
 pk_hand_off_api.get_resp_icons(aux_sql.sys_lang,
                                profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                                ei.id_episode,
                                aux_sql.sys_hand_off_type) resp_icons,
 id_prof_order
  FROM sys_alert_event sae
  JOIN aux_sql
    ON sae.id_sys_alert = aux_sql.id_sys_alert
 INNER JOIN patient p
    ON sae.id_patient = p.id_patient
 INNER JOIN epis_info ei
    ON sae.id_episode = ei.id_episode
 INNER JOIN v_episode_act vea
    ON sae.id_episode = vea.id_episode
 INNER JOIN blood_product_det bpd
    ON sae.id_record = bpd.id_blood_product_det
 INNER JOIN hemo_type ht
    ON bpd.id_hemo_type = ht.id_hemo_type
 WHERE sae.id_sys_alert = 335
   AND sae.id_institution = aux_sql.sys_institution
   AND (sae.id_software = aux_sql.sys_software OR EXISTS
        (SELECT 1
           FROM v_episode_act ve
           JOIN epis_type_soft_inst etsi
             ON etsi.id_epis_type = ve.id_epis_type
            AND etsi.id_institution IN (0, aux_sql.sys_institution)
          WHERE ve.id_visit = vea.id_visit
            AND etsi.id_software = sae.id_software
            AND ve.flg_status_e = 'A'))
   AND bpd.flg_status NOT IN ('CR')
   AND pk_alerts.get_config_flg_read(aux_sql.sys_lang,
                                     profissional(aux_sql.sys_id_prof, aux_sql.sys_institution, aux_sql.sys_software),
                                     sae.id_sys_alert,
                                     NULL) = 'N'
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sae.id_sys_alert_event = sar.id_sys_alert_event
           AND sar.id_professional = aux_sql.sys_id_prof)
   AND pk_alerts.check_if_alert_expired(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                     sys_context('ALERT_CONTEXT', 'i_institution'),
                                                     sys_context('ALERT_CONTEXT', 'i_software')),
                                        sae.dt_creation,
                                        sae.id_sys_alert) > 0;