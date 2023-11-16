CREATE OR REPLACE VIEW V_SYS_ALERT_323 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 sae.id_sys_alert_event id_sys_alert_det,
 sae.id_record id_reg,
 sae.id_episode,
 sae.id_institution,
 sae.id_professional id_prof,
 pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    sae.dt_record,
                                    'YYYYMMDDHH24MISS') dt_req,
 decode(nvl(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record), ':'), 0),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record) || ' ' ||
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 pk_message.get_message(i_lang => sys_context('ALERT_CONTEXT', 'i_lang'), i_code_mess => 'BLOOD_PRODUCTS_T95') || ' (' ||
 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), ht.code_hemo_type) || ')' message,
 ei.id_room,
 sae.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         ei.id_patient,
                         ei.id_episode,
                         ei.id_schedule) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 ei.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    ei.id_patient) pat_nd_icon,
 pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                        sys_context('ALERT_CONTEXT', 'i_software')),
                           ei.id_patient,
                           ei.id_episode,
                           ei.id_schedule) photo,
 p.gender,
 pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                        p.dt_birth,
                        p.age,
                        sys_context('ALERT_CONTEXT', 'i_institution'),
                        sys_context('ALERT_CONTEXT', 'i_software')) pat_age,
 (SELECT coalesce(r.desc_room_abbreviation,
                  pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_abbreviation),
                  r.desc_room,
                  pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_room))
    FROM room r
   WHERE ei.id_room = r.id_room) desc_room,
 (SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), e.dt_begin_tstz)
    FROM episode e
   WHERE sae.id_episode = e.id_episode) date_send,
 pk_edis_grid.get_complaint_grid(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                 sys_context('ALERT_CONTEXT', 'i_software'),
                                 sae.id_episode) desc_epis_anamnesis,
 nvl(ei.triage_acuity, '0x787864') acuity,
 nvl(ei.triage_rank_acuity, 999) rank_acuity,
 NULL id_schedule,
 pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                               sae.id_sys_alert) id_sys_shortcut,
 sae.id_sys_alert_event id_reg_det,
 sae.id_sys_alert,
 pk_episode.get_epis_dt_first_obs(ei.id_episode, ei.dt_first_obs_tstz, NULL, 'Y') dt_first_obs_tstz,
 pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                sys_context('ALERT_CONTEXT', 'i_software')),
                                   ei.id_episode,
                                   NULL,
                                   ei.id_triage_color,
                                   NULL,
                                   vea.has_transfer) fast_track_icon,
 decode(ei.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
 'A' fast_track_status,
 pk_edis_triage.get_epis_esi_level(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                sys_context('ALERT_CONTEXT', 'i_software')),
                                   ei.id_episode,
                                   ei.id_triage_color) esi_level,
 pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 p.id_patient,
                                 ei.id_episode) name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                ei.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event sae
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
 WHERE sae.id_sys_alert = 323
   AND sae.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND (sae.id_software = sys_context('ALERT_CONTEXT', 'i_software') OR EXISTS
        (SELECT 1
           FROM v_episode_act ve
           JOIN epis_type_soft_inst etsi
             ON etsi.id_epis_type = ve.id_epis_type
            AND etsi.id_institution IN (0, sys_context('ALERT_CONTEXT', 'i_institution'))
          WHERE ve.id_visit = vea.id_visit
            AND etsi.id_software = sae.id_software
            AND ve.flg_status_e = 'A'))
   AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                     profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                  sys_context('ALERT_CONTEXT', 'i_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_software')),
                                     sae.id_sys_alert,
                                     NULL) != 'N'
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sae.id_sys_alert_event = sar.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof'))
   AND pk_alerts.check_if_alert_expired(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                     sys_context('ALERT_CONTEXT', 'i_institution'),
                                                     sys_context('ALERT_CONTEXT', 'i_software')),
                                        sae.dt_creation,
                                        sae.id_sys_alert) > 0;
