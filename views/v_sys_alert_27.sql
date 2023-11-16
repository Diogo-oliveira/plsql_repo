CREATE OR REPLACE   VIEW V_SYS_ALERT_27 AS
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
 REPLACE(REPLACE(pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M028'),
                 '@1',
                 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), v.replace1)),
         '@2',
         v.replace2) message,
 NULL id_room,
 p.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                         p.id_patient,
                         v.id_episode) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                 p.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                       sys_context('ALERT_CONTEXT', 'i_institution'),
                                                       sys_context('ALERT_CONTEXT', 'i_software')),
                                    p.id_patient) pat_nd_icon,
 pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                           alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                           e.id_patient,
                           e.id_episode,
                           ei.id_schedule) photo,
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
 ei.triage_acuity acuity,
 ei.triage_rank_acuity rank_acuity,
 NULL id_schedule,
 pk_alerts.get_alerts_shortcut(alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                  sys_context('ALERT_CONTEXT', 'i_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_software')),
                               v.id_sys_alert) id_sys_shortcut,
 v.id_record id_reg_det,
 v.id_sys_alert,
 pk_episode.get_epis_dt_first_obs(ei.id_episode, ei.dt_first_obs_tstz, NULL, 'Y') dt_first_obs_tstz,
 pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
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
                                           alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                           v.id_episode,
                                           ei.id_triage_color)
    FROM dual) esi_level,
 pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                 p.id_patient,
                                 v.id_episode) name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                   sys_context('ALERT_CONTEXT', 'i_institution'),
                                                   sys_context('ALERT_CONTEXT', 'i_software')),
                                v.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event v, episode e, epis_info ei, patient p, professional pf, room r
 WHERE v.id_sys_alert = 27
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.id_episode = e.id_episode
   AND e.id_patient = p.id_patient
   AND v.flg_visible = 'Y'
   AND pf.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
   AND pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(alert.profissional(NULL, v.id_institution, NULL),
                                                                       current_timestamp,
                                                                       NULL),
                                      -pk_sysconfig.get_config('ALERT_EXPIRE_TRANSFER_REQ',
                                                               v.id_institution,
                                                               v.id_software)) <
       pk_date_utils.trunc_insttimezone(alert.profissional(NULL, v.id_institution, NULL), v.dt_record, NULL)
   AND EXISTS
 (SELECT 1
          FROM sys_alert_prof sap
         WHERE sap.id_sys_alert = v.id_sys_alert
           AND sap.id_institution = v.id_institution
           AND sap.id_software = sys_context('ALERT_CONTEXT', 'i_software')
           AND sap.id_professional = pf.id_professional)
   AND pf.id_professional IN (SELECT pdc.id_professional
                                FROM department dpt, dep_clin_serv dcs, prof_dep_clin_serv pdc, epis_prof_resp epr
                               WHERE pdc.flg_status = 'S'
                                 AND pdc.id_dep_clin_serv = dcs.id_dep_clin_serv
                                 AND dpt.id_department = dcs.id_department
                                 AND instr(dpt.flg_type, 'I') > 0
                                 AND epr.id_epis_prof_resp = v.id_record
                                 AND dpt.id_department = epr.id_department_orig)
   AND NOT EXISTS
 (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = v.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                sys_context('ALERT_CONTEXT', 'i_software')),
                                             v.id_sys_alert,
                                             NULL) = 'N')
   AND e.id_episode = ei.id_episode
   AND ei.id_room = r.id_room
and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software'))
									  , i_dt_creation  => v.dt_creation
									  , i_id_sys_alert => v.id_sys_alert ) > 0
   ;
