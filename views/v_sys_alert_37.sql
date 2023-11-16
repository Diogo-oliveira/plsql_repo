CREATE OR REPLACE   VIEW V_SYS_ALERT_37 AS
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
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')) TIME,
 REPLACE(REPLACE(pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M038'),
                 '@1',
                 pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), v.replace1)),
         '@2',
         v.replace2) message,
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
                           e.id_patient,
                           e.id_episode,
                           NULL) photo,
 pk_patient.get_gender(sys_context('ALERT_CONTEXT', 'i_lang'), p.gender) gender,
 pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                        p.id_patient,
                        sys_context('ALERT_CONTEXT', 'i_institution'),
                        sys_context('ALERT_CONTEXT', 'i_software')) pat_age,
 coalesce(r.desc_room_abbreviation,
          pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_abbreviation),
          r.desc_room,
          pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_room)) desc_room,
 pk_date_utils.get_elapsed_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), e.dt_begin_tstz, current_timestamp) date_send,
 decode(sys_context('ALERT_CONTEXT', 'i_software'),
        11,
        pk_diagnosis.get_epis_diagnosis(sys_context('ALERT_CONTEXT', 'i_lang'), e.id_episode),
        pk_edis_grid.get_complaint_grid(sys_context('ALERT_CONTEXT', 'i_lang'),
                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                        sys_context('ALERT_CONTEXT', 'i_software'),
                                        e.id_episode)) desc_epis_anamnesis,
 decode(ei.triage_acuity, NULL, '0x787864', ei.triage_acuity) acuity,
 decode(ei.triage_rank_acuity, NULL, 999, ei.triage_rank_acuity) rank_acuity,
 NULL id_schedule,
 sw.id_sys_shortcut,
 v.id_sys_alert_event id_reg_det,
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
                                 e.id_patient,
                                 v.id_episode) name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                e.id_episode,
                                NULL) resp_icons,
 id_prof_order
  FROM sys_alert_event v,
       episode e,
       epis_info ei,
       patient p,
       room r,
       sys_alert_config sw,
       (SELECT prt.id_profile_template
          FROM prof_profile_template ppt, profile_template prt
         WHERE prt.id_templ_assoc IS NOT NULL
           AND ppt.id_profile_template = prt.id_profile_template
           AND ppt.id_software = sys_context('ALERT_CONTEXT', 'i_software')
           AND ppt.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND id_professional = sys_context('ALERT_CONTEXT', 'i_prof')) ppt
 WHERE sw.id_software = sys_context('ALERT_CONTEXT', 'i_software')
   AND sw.id_sys_alert = v.id_sys_alert
   AND sw.id_profile_template = ppt.id_profile_template
   AND v.id_sys_alert = 37
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.flg_visible = 'Y'
   AND e.id_episode = v.id_episode
   AND e.id_episode = ei.id_episode
   AND ei.id_room = r.id_room
   AND p.id_patient = e.id_patient
and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software'))
									  , i_dt_creation  => v.dt_creation
									  , i_id_sys_alert => v.id_sys_alert ) > 0
   ;
