CREATE OR REPLACE VIEW V_SYS_ALERT_200 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 ed.id_episode,
 epis.id_institution,
 sys_context('ALERT_CONTEXT', 'i_prof') id_prof,
 pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                             nvl(r.dt_review, ed.dt_last_update_tstz),
                             epis.id_institution,
                             ei.id_software) dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                    nvl(r.dt_review, ed.dt_last_update_tstz)),
              ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                              nvl(r.dt_review, ed.dt_last_update_tstz)),
        pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                              nvl(r.dt_review, ed.dt_last_update_tstz)) || ' ' ||
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'MSG_REMIN_B001') message,
 NULL id_room,
 epis.id_patient id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         epis.id_patient,
                         epis.id_episode) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 epis.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    epis.id_patient) pat_nd_icon,
 NULL photo,
 pk_patient.get_gender(sys_context('ALERT_CONTEXT', 'i_lang'), nvl(pat.gender, 'I')) gender,
 pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                        pat.dt_birth,
                        pat.age,
                        sys_context('ALERT_CONTEXT', 'i_prof'),
                        ei.id_software) pat_age,
 NULL desc_room,
 NULL date_send,
 NULL desc_epis_anamnesis,
 ei.triage_acuity acuity,
 ei.triage_rank_acuity rank_acuity,
 NULL id_schedule,
 pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software')),
                               v.id_sys_alert) id_sys_shortcut,
 NULL id_reg_det,
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
                                 epis.id_patient,
                                 epis.id_episode) name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                v.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event v
  JOIN epis_documentation ed
    ON ed.id_epis_documentation = v.id_record
  JOIN episode epis
    ON epis.id_episode = ed.id_episode
  JOIN epis_info ei
    ON ei.id_episode = epis.id_episode
  JOIN patient pat
    ON pat.id_patient = epis.id_patient
  LEFT JOIN review_detail r
    ON r.flg_context = 'AD'
   AND r.id_record_area = ed.id_epis_documentation
   AND pk_prof_utils.get_category(sys_context('ALERT_CONTEXT', 'i_lang'),
                                  profissional(r.id_professional, epis.id_institution, ei.id_software)) =
       pk_prof_utils.get_category(sys_context('ALERT_CONTEXT', 'i_lang'),
                                  profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                               sys_context('ALERT_CONTEXT', 'i_institution'),
                                               sys_context('ALERT_CONTEXT', 'i_software')))
 WHERE v.id_sys_alert = 200
   AND v.id_software = sys_context('ALERT_CONTEXT', 'i_software')
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.flg_visible = 'Y'
   AND ed.flg_status = 'A'
   AND pk_advanced_directives.is_to_review_dnar(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                                pat.id_patient,
                                                epis.id_episode) = 'Y'
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = v.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          epis.id_institution,
                                                          ei.id_software),
                                             v.id_sys_alert,
                                             NULL) = 'N')
  and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                            sys_context('ALERT_CONTEXT', 'i_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_software'))
                    , i_dt_creation  => v.dt_creation
                    , i_id_sys_alert => v.id_sys_alert ) > 0 
 --ORDER BY ed.dt_last_update_tstz
 ;
