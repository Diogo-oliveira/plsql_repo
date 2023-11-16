CREATE OR REPLACE   VIEW V_SYS_ALERT_32 AS
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
 pk_alerts.get_alert_message(sys_context('ALERT_CONTEXT', 'i_lang'),
                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                          sys_context('ALERT_CONTEXT', 'i_software')),
                             v.id_sys_alert,
                             v.replace1,
                             v.replace2) message,
 NULL id_room,
 p.id_patient,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_software')),
                         p.id_patient,
                         v.id_episode) name_pat,
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
 pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
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
                                 v.id_episode) name_pat_sort,
 pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                v.id_episode,
                                sys_context('ALERT_CONTEXT', 'l_hand_off_type')) resp_icons,
 id_prof_order
  FROM sys_alert_event v, episode e, patient p, professional pf, epis_info ei, room r, prof_cat pc, category c
 WHERE v.id_sys_alert = 32
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND e.id_episode = v.id_episode
   AND p.id_patient = e.id_patient
   AND pc.id_category = c.id_category
   AND pf.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
   AND pf.id_professional = pc.id_professional
   AND pc.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND ((v.id_professional IS NOT NULL AND v.id_professional = pf.id_professional) OR
       (v.id_professional IS NULL AND EXISTS
        (SELECT 1
            FROM epis_multi_prof_resp empr
           WHERE empr.flg_resp_type = 'O'
             AND empr.id_epis_prof_resp = v.id_record
             AND empr.flg_status = 'H'
             AND empr.flg_profile = sys_context('ALERT_CONTEXT', 'l_flg_profile')
             AND empr.id_speciality = pf.id_speciality)) OR
       (v.id_professional IS NULL AND EXISTS
        (SELECT 1
            FROM prof_dep_clin_serv pdcs, epis_prof_resp epr
           WHERE epr.id_epis_prof_resp = v.id_record
             AND ((sys_context('ALERT_CONTEXT', 'l_hand_off_type') = 'M' AND
                 epr.id_epis_prof_resp IN
                 (SELECT empr.id_epis_prof_resp
                      FROM epis_multi_prof_resp empr
                     WHERE empr.id_episode = epr.id_episode
                       AND empr.flg_profile = sys_context('ALERT_CONTEXT', 'l_flg_profile'))) OR
                 sys_context('ALERT_CONTEXT', 'l_hand_off_type') = 'N')
             AND ((pdcs.id_dep_clin_serv IN (SELECT dcs2.id_dep_clin_serv
                                               FROM dep_clin_serv dcs2
                                               JOIN department dpt
                                                 ON dpt.id_department = dcs2.id_department
                                              WHERE dcs2.id_clinical_service = epr.id_clinical_service_dest
                                                AND dpt.id_software = ei.id_software)) OR
                 (pdcs.id_dep_clin_serv IN
                 (SELECT dcs.id_dep_clin_serv
                      FROM dep_clin_serv dcs
                     WHERE dcs.id_department = epr.id_department_dest) AND pc.id_category = 2))
             AND pdcs.flg_status = 'S'
             AND epr.flg_type = c.flg_type
             AND epr.id_prof_req <> sys_context('ALERT_CONTEXT', 'i_prof')
             AND epr.flg_type = c.flg_type
             AND epr.flg_transf_type = 'I'
             AND pdcs.id_professional = pf.id_professional)))
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
   AND e.id_episode = ei.id_episode
   AND ei.id_room = r.id_room
   AND v.flg_visible = 'Y'
and pk_alerts.check_if_alert_expired( i_prof => profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_software'))
									  , i_dt_creation  => v.dt_creation
                    , i_id_sys_alert => v.id_sys_alert ) > 0;
