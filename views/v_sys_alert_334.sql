CREATE OR REPLACE VIEW V_SYS_ALERT_334 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 sae.id_sys_alert_event id_sys_alert_det,
 sae.id_record id_reg,
 sae.id_episode,
 sae.id_institution,
 sae.id_professional id_prof,
 (SELECT pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                                         sys_context('ALERT_CONTEXT', 'i_software')),
                                            sae.dt_record,
                                            'YYYYMMDDHH24MISS')
    FROM dual) dt_req,
 decode(nvl(instr((SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record)
                    FROM dual),
                  ':'),
            0),
        0,
        (SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record)
           FROM dual),
        (SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record)
           FROM dual) || ' ' || (SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')
                                   FROM dual)) TIME,
 (SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M334')
    FROM dual) message,
 ei.id_room,
 sae.id_patient,
 (SELECT pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 ei.id_patient,
                                 ei.id_episode,
                                 ei.id_schedule)
    FROM dual) name_pat,
 (SELECT pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software')),
                                         ei.id_patient)
    FROM dual) pat_ndo,
 (SELECT pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                            profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                                         sys_context('ALERT_CONTEXT', 'i_software')),
                                            ei.id_patient)
    FROM dual) pat_nd_icon,
 (SELECT pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                sys_context('ALERT_CONTEXT', 'i_software')),
                                   ei.id_patient,
                                   ei.id_episode,
                                   ei.id_schedule)
    FROM dual) photo,
 p.gender,
 (SELECT pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                                p.dt_birth,
                                p.age,
                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                sys_context('ALERT_CONTEXT', 'i_software'))
    FROM dual) pat_age,
 (SELECT coalesce(r.desc_room_abbreviation,
                  (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_abbreviation)
                     FROM dual),
                  r.desc_room,
                  (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_room)
                     FROM dual))
    FROM room r
   WHERE ei.id_room = r.id_room) desc_room,
 (SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), e.dt_begin_tstz)
    FROM episode e
   WHERE sae.id_episode = e.id_episode) date_send,
 (SELECT pk_edis_grid.get_complaint_grid(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                         sys_context('ALERT_CONTEXT', 'i_software'),
                                         sae.id_episode)
    FROM dual) desc_epis_anamnesis,
 nvl(ei.triage_acuity, '0x787864') acuity,
 nvl(ei.triage_rank_acuity, 999) rank_acuity,
 NULL id_schedule,
 (SELECT pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                       sae.id_sys_alert)
    FROM dual) id_sys_shortcut,
 sae.id_sys_alert_event id_reg_det,
 sae.id_sys_alert,
 (SELECT pk_episode.get_epis_dt_first_obs(ei.id_episode, ei.dt_first_obs_tstz, NULL, 'Y')
    FROM dual) dt_first_obs_tstz,
 (SELECT pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_software')),
                                           ei.id_episode,
                                           NULL,
                                           ei.id_triage_color,
                                           NULL,
                                           vea.has_transfer)
    FROM dual) fast_track_icon,
 decode(ei.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
 'A' fast_track_status,
 (SELECT pk_edis_triage.get_epis_esi_level(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_software')),
                                           ei.id_episode,
                                           ei.id_triage_color)
    FROM dual) esi_level,
 (SELECT pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software')),
                                         p.id_patient,
                                         ei.id_episode)
    FROM dual) name_pat_sort,
 (SELECT pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                        profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                     sys_context('ALERT_CONTEXT', 'i_institution'),
                                                     sys_context('ALERT_CONTEXT', 'i_software')),
                                        ei.id_episode,
                                        sys_context('ALERT_CONTEXT', 'l_hand_off_type'))
    FROM dual) resp_icons,
 id_prof_order
  FROM sys_alert_event sae
 INNER JOIN patient p
    ON sae.id_patient = p.id_patient
 INNER JOIN epis_info ei
    ON sae.id_episode = ei.id_episode
 INNER JOIN v_episode_act vea
    ON sae.id_episode = vea.id_episode
 WHERE sae.id_sys_alert = 334
   AND sae.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sae.id_sys_alert_event = sar.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof'))
   AND pk_alerts.check_if_alert_expired(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                     sys_context('ALERT_CONTEXT', 'i_institution'),
                                                     sys_context('ALERT_CONTEXT', 'i_software')),
                                        sae.dt_creation,
                                        sae.id_sys_alert) > 0;
