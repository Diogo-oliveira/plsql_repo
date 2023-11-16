CREATE OR REPLACE   VIEW V_SYS_ALERT_9 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 v.id_episode,
 v.id_institution,
 v.id_professional id_prof,
 pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    v.dt_record,
                                    'YYYYMMDDHH24MISS') dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record), ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record) || ' ' ||
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 REPLACE(pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M006'), '@1', v.replace1) message,
 NULL id_room,
 e.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         e.id_patient,
                         v.id_episode) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 e.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    e.id_patient) pat_nd_icon,
 pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                        sys_context('ALERT_CONTEXT', 'i_software')),
                           ei.id_patient,
                           ei.id_episode,
                           ei.id_schedule) AS photo,
 p.gender,
 pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                        p.id_patient,
                        sys_context('ALERT_CONTEXT', 'i_institution'),
                        sys_context('ALERT_CONTEXT', 'i_software')) pat_age,
 coalesce(r.desc_room_abbreviation,
          pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_abbreviation),
          r.desc_room,
          pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_room)) desc_room,
 pk_date_utils.get_elapsed_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), e.dt_begin_tstz, current_timestamp) date_send,
 pk_edis_grid.get_complaint_grid(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                 sys_context('ALERT_CONTEXT', 'i_software'),
                                 e.id_episode) desc_epis_anamnesis,
 nvl(ei.triage_acuity, '0x787864') acuity,
 nvl(ei.triage_rank_acuity, 999) rank_acuity,
 NULL id_schedule,
 pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                               v.id_sys_alert) id_sys_shortcut,
 v.id_record id_reg_det,
 v.id_sys_alert,
 pk_episode.get_epis_dt_first_obs(ei.id_episode, ei.dt_first_obs_tstz, NULL, 'Y') dt_first_obs_tstz,
 pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                sys_context('ALERT_CONTEXT', 'i_software')),
                                   v.id_episode,
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
                                           v.id_episode,
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
                                v.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event v
  JOIN episode e
    ON e.id_episode = v.id_episode
  JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  JOIN patient p
    ON p.id_patient = e.id_patient
  JOIN room r
    ON r.id_room = ei.id_room
 WHERE v.id_sys_alert = 9
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.flg_visible = 'Y'
   AND v.dt_record <
       pk_date_utils.add_days_to_tstz(current_timestamp,
                                      - (pk_sysconfig.get_config('ALERT_PATIENT_MOV_TIMEOUT',
                                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                sys_context('ALERT_CONTEXT', 'i_software')) / (24 * 60)))
   AND EXISTS (SELECT 1
          FROM sys_alert_prof sap
         WHERE sap.id_sys_alert = 9
           AND id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND sap.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND sap.id_software = sys_context('ALERT_CONTEXT', 'i_software'))
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = v.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                             v.id_sys_alert,
                                             NULL) = 'N')
and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software'))
									  , i_dt_creation  => v.dt_creation
									  , i_id_sys_alert => v.id_sys_alert ) > 0
;
