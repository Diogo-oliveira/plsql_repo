CREATE OR REPLACE   VIEW V_SYS_ALERT_43 AS
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
                                    'YYYYMMDDHH24MISS') AS dt_req,
 pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record) ||
 decode(nvl(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record), ':'), 0),
        0,
        NULL,
        ' ' || pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 REPLACE(pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M007'),
         '@1',
         pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record) ||
         decode(nvl(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), sae.dt_record),
                          ':'),
                    0),
                0,
                NULL,
                ' ' || pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003'))) message,
 ei.id_room,
 sae.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         sae.id_patient,
                         sae.id_episode) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 sae.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    sae.id_patient) pat_nd_icon,
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
                                   sae.id_episode,
                                   NULL,
                                   ei.id_triage_color,
                                   NULL,
                                   NULL) fast_track_icon,
 decode(ei.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
 'A' fast_track_status,
 (SELECT pk_edis_triage.get_epis_esi_level(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_software')),
                                           sae.id_episode,
                                           ei.id_triage_color)
    FROM dual) esi_level,
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
                                sae.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event sae
 INNER JOIN patient p
    ON sae.id_patient = p.id_patient
 INNER JOIN epis_info ei
    ON sae.id_episode = ei.id_episode
 WHERE sae.id_sys_alert = 43
   AND sae.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND (sae.id_professional = sys_context('ALERT_CONTEXT', 'i_prof') OR EXISTS
        (SELECT 1
           FROM dep_clin_serv dcs
          INNER JOIN prof_dep_clin_serv pdcs
             ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
          WHERE sae.id_clinical_service = dcs.id_clinical_service
            AND pdcs.flg_status = 'S'
            AND pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')))
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
   AND pk_date_utils.diff_timestamp(current_timestamp, sae.dt_record) > 0
and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software'))
									  , i_dt_creation  => sae.dt_creation
									  , i_id_sys_alert => sae.id_sys_alert ) > 0
   ;
