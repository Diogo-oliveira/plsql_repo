CREATE OR REPLACE VIEW v_sys_alert_322 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 v.id_episode,
 v.id_institution,
 sys_context('ALERT_CONTEXT', 'i_prof') id_prof,
 pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    v.dt_record,
                                    'YYYYMMDDHH24MISS') dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record), ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record) || ' ' ||
        (SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')
           FROM dual)) TIME,
 REPLACE((SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M322')
           FROM dual),
         '@1',
         tci.reassess_time) message,
 NULL id_room,
 gea.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         gea.id_patient,
                         v.id_episode) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 gea.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    gea.id_patient) pat_nd_icon,
 decode(pk_patphoto.check_blob(gea.id_patient),
        'N',
        '',
        pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                                  profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                               sys_context('ALERT_CONTEXT', 'i_institution'),
                                               sys_context('ALERT_CONTEXT', 'i_software')),
                                  gea.id_patient,
                                  gea.id_episode,
                                  gea.id_schedule)) photo,
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
    FROM dual) desc_room,
 pk_date_utils.get_elapsed_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), gea.dt_begin_tstz, current_timestamp) date_send,
 pk_edis_grid.get_complaint_grid(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                 sys_context('ALERT_CONTEXT', 'i_software'),
                                 gea.id_episode) desc_epis_anamnesis,
 gea.triage_acuity acuity,
 gea.triage_rank_acuity rank_acuity,
 NULL id_schedule,
 pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                               v.id_sys_alert) id_sys_shortcut,
 v.id_record id_reg_det,
 v.id_sys_alert,
 pk_episode.get_epis_dt_first_obs(gea.id_episode, gea.dt_first_obs_tstz, NULL, 'Y') dt_first_obs_tstz,
 pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                sys_context('ALERT_CONTEXT', 'i_software')),
                                   v.id_episode,
                                   NULL,
                                   gea.id_triage_color,
                                   NULL,
                                   NULL) fast_track_icon,
 decode(gea.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
 'A' fast_track_status,
 (SELECT pk_edis_triage.get_epis_esi_level(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_software')),
                                           v.id_episode,
                                           gea.id_triage_color)
    FROM dual) esi_level,
 pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 p.id_patient,
                                 v.id_episode) name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                v.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event v
  JOIN sys_alert sa
    ON sa.id_sys_alert = v.id_sys_alert
  JOIN grids_ea gea
    ON gea.id_episode = v.id_episode
  JOIN patient p
    ON p.id_patient = gea.id_patient
  JOIN room r
    ON r.id_room = gea.id_room
  JOIN triage_color tco
    ON gea.id_triage_color = tco.id_triage_color
  LEFT JOIN triage_color_time_inst tci
    ON tci.id_triage_color = tco.id_triage_color
 WHERE v.id_sys_alert = 322
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.flg_visible = 'Y'
   AND v.dt_record < pk_date_utils.add_days_to_tstz(current_timestamp, - (tci.reassess_time / (24 * 60)))
   AND tci.reassess_time > 0
   AND NOT EXISTS
 (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = v.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                             v.id_sys_alert,
                                             NULL) = 'N')
   AND (tci.id_triage_color IS NULL OR
       (tci.id_institution = 0 AND NOT EXISTS (SELECT 0
                                                  FROM triage_color_time_inst t1
                                                 WHERE t1.id_triage_color = tco.id_triage_color
                                                   AND t1.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')) OR
        tci.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')));
