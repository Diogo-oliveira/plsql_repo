CREATE OR REPLACE VIEW v_sys_alert_50 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 v.id_episode,
 v.id_institution,
 pf.id_professional id_prof,
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
 decode(v.id_intf_type,
        1,
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M047'),
        2,
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M048'),
        3,
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M049'),
        4,
        pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'V_ALERT_M050')) message,
 NULL id_room,
 p.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         p.id_patient,
                         v.id_episode,
                         NULL) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 p.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                 sys_context('ALERT_CONTEXT', 'i_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_software')),
                                    p.id_patient) pat_nd_icon,
 pk_patphoto.get_pat_foto(p.id_patient,
                          sys_context('ALERT_CONTEXT', 'i_institution'),
                          sys_context('ALERT_CONTEXT', 'i_software')) photo,
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
                                   e.id_episode,
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
                                           e.id_episode,
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
                                v.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event v, professional pf, episode e, epis_info ei, patient p, room r
 WHERE v.id_sys_alert = 50
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.flg_visible = 'Y'
   AND v.dt_record >=
       pk_date_utils.add_days_to_tstz(current_timestamp,
                                      - (pk_sysconfig.get_config('ALERT_INTF_TIMEOUT', v.id_institution, v.id_software) / 24))
   AND v.id_episode = e.id_episode
   AND e.id_patient = p.id_patient
   AND ei.id_episode = e.id_episode
   AND e.id_episode = ei.id_episode
   AND ei.id_room = r.id_room
   AND pf.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
   AND (v.id_intf_type IN (1, 2) AND
       (pf.id_professional IN (SELECT id_professional
                                  FROM epis_info ei
                                 WHERE ei.id_episode = v.id_episode
                                   AND ei.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                                UNION
                                SELECT pdcs.id_professional
                                  FROM epis_info ei, dep_clin_serv dcs, prof_dep_clin_serv pdcs, prof_cat pc, category c
                                 WHERE dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                   AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                   AND pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                                   AND pc.id_professional = pdcs.id_professional
                                   AND c.id_category = pc.id_category
                                   AND c.flg_type = 'N'
                                UNION
                                SELECT v.id_professional
                                  FROM dual
                                UNION
                                SELECT pr.id_professional
                                  FROM prof_room pr, prof_cat pc, category c
                                 WHERE pr.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                                   AND pr.id_room = v.id_room
                                   AND pc.id_professional = pr.id_professional
                                   AND c.id_category = pc.id_category
                                   AND c.flg_type = 'N'
                                UNION
                                SELECT cst.id_prof_dest
                                  FROM co_sign_task cst
                                 WHERE cst.flg_type IN ('A', 'E')
                                   AND cst.id_task = v.id_record
                                   AND cst.id_prof_dest = sys_context('ALERT_CONTEXT', 'i_prof')
                                UNION
                                SELECT csh.id_prof_ordered_by
                                  FROM analysis_req_det ard, co_sign_hist csh
                                 WHERE ard.id_analysis_req_det = v.id_record
                                   AND ard.id_co_sign_order = csh.id_co_sign_hist
                                   AND v.id_intf_type = 1
                                UNION
                                SELECT csh.id_prof_ordered_by
                                  FROM exam_req_det erd, co_sign_hist csh
                                 WHERE erd.id_exam_req_det = v.id_record
                                   AND erd.id_co_sign_order = csh.id_co_sign_hist
                                   AND v.id_intf_type = 2
                                UNION
                                SELECT ppt.id_professional
                                  FROM prof_profile_template ppt
                                 WHERE ppt.id_institution = v.id_institution
                                   AND ppt.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                                   AND ppt.id_software = 15
                                   AND ppt.id_profile_template = 21
                                   AND v.id_intf_type = 2
                                UNION
                                SELECT ppt.id_professional
                                  FROM prof_profile_template ppt
                                 WHERE ppt.id_institution = v.id_institution
                                   AND ppt.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                                   AND ppt.id_software = 33
                                   AND ppt.id_profile_template = 411
                                   AND v.id_intf_type = 1)) OR (v.id_intf_type IN (3, 4)))
   AND NOT EXISTS (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = v.id_sys_alert_event
           AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
           AND pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                             v.id_sys_alert,
                                             NULL) = 'N');
