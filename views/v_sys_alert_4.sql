CREATE OR REPLACE VIEW V_SYS_ALERT_4 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 t.id_sys_alert_event id_sys_alert_det,
 t.id_record id_reg,
 t.id_episode,
 t.id_institution,
 sys_context('ALERT_CONTEXT', 'i_prof') id_prof,
 (SELECT pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                                         sys_context('ALERT_CONTEXT', 'i_software')),
                                            t.dt_record,
                                            'YYYYMMDDHH24MISS')
    FROM dual) dt_req,
 decode(instr((SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), t.dt_record)
                FROM dual),
              ':'),
        0,
        (SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), t.dt_record)
           FROM dual),
        (SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), t.dt_record)
           FROM dual) || ' ' || (SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')
                                   FROM dual)) TIME,
 (SELECT pk_alerts.get_alert_message(sys_context('ALERT_CONTEXT', 'i_lang'),
                                     profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                  sys_context('ALERT_CONTEXT', 'i_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_software')),
                                     t.id_sys_alert,
                                     (SELECT pk_lab_tests_api_db.get_alias_translation(sys_context('ALERT_CONTEXT',
                                                                                                   'i_lang'),
                                                                                       profissional(sys_context('ALERT_CONTEXT',
                                                                                                                'i_prof'),
                                                                                                    sys_context('ALERT_CONTEXT',
                                                                                                                'i_institution'),
                                                                                                    sys_context('ALERT_CONTEXT',
                                                                                                                'i_software')),
                                                                                       NULL,
                                                                                       t.replace1,
                                                                                       NULL)
                                        FROM dual),
                                     pk_sysconfig.get_config('ALERT_HARVEST_TIMEOUT', t.id_institution, t.id_software),
                                     'N')
    FROM dual) message,
 NULL id_room,
 t.id_patient,
 (SELECT pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 t.id_patient,
                                 t.id_episode,
                                 t.id_schedule)
    FROM dual) name_pat,
 (SELECT pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software')),
                                         t.id_patient)
    FROM dual) pat_ndo,
 (SELECT pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                            profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                                         sys_context('ALERT_CONTEXT', 'i_software')),
                                            t.id_patient)
    FROM dual) pat_nd_icon,
 (SELECT pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                sys_context('ALERT_CONTEXT', 'i_software')),
                                   t.id_patient,
                                   t.id_episode,
                                   NULL)
    FROM dual) photo,
 t.gender,
 (SELECT pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                                t.id_patient,
                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                sys_context('ALERT_CONTEXT', 'i_software'))
    FROM dual) pat_age,
 coalesce(t.desc_room_abbreviation,
          (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), t.code_abbreviation)
             FROM dual),
          t.desc_room,
          (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), t.code_room)
             FROM dual)) desc_room,
 (SELECT pk_date_utils.get_elapsed_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), t.dt_begin_tstz, current_timestamp)
    FROM dual) date_send,
 (SELECT pk_edis_grid.get_complaint_grid(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                         sys_context('ALERT_CONTEXT', 'i_software'),
                                         t.id_episode)
    FROM dual) desc_epis_anamnesis,
 t.triage_acuity acuity,
 t.triage_rank_acuity rank_acuity,
 NULL id_schedule,
 (SELECT pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                       t.id_sys_alert)
    FROM dual) id_sys_shortcut,
 t.id_record id_reg_det,
 t.id_sys_alert,
 pk_episode.get_epis_dt_first_obs(t.id_episode, t.dt_first_obs_tstz, NULL, 'Y') dt_first_obs_tstz,
 (SELECT pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_software')),
                                           t.id_episode,
                                           NULL,
                                           t.id_triage_color,
                                           NULL,
                                           NULL)
    FROM dual) fast_track_icon,
 decode(t.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
 'A' fast_track_status,
 (SELECT pk_edis_triage.get_epis_esi_level(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_software')),
                                           t.id_episode,
                                           t.id_triage_color)
    FROM dual) esi_level,
 (SELECT pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software')),
                                         t.id_patient,
                                         t.id_episode)
    FROM dual) name_pat_sort,
 (SELECT pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                        profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                     sys_context('ALERT_CONTEXT', 'i_institution'),
                                                     sys_context('ALERT_CONTEXT', 'i_software')),
                                        t.id_episode,
                                        sys_context('ALERT_CONTEXT', 'l_hand_off_type'))
    FROM dual) resp_icons,
 id_prof_order
  FROM (SELECT v.id_sys_alert_event,
               v.id_record,
               v.id_episode,
               v.id_institution,
               v.dt_record,
               v.id_sys_alert,
               v.replace1,
               v.id_software,
               p.id_patient,
               ei.id_schedule,
               p.gender,
               r.desc_room_abbreviation,
               r.desc_room,
               r.code_room,
               r.code_abbreviation,
               e.dt_begin_tstz,
               ei.triage_acuity,
               ei.triage_rank_acuity,
               ei.dt_first_obs_tstz,
               ei.id_triage_color,
               id_prof_order
          FROM sys_alert_event v, episode e, epis_info ei, patient p, room r, v_prof_alerts vpa
         WHERE v.id_sys_alert = 4
           AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND v.flg_visible = 'Y'
           AND (SELECT pk_date_utils.add_days_to_tstz((SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                           v.id_institution,
                                                                                                           NULL),
                                                                                              current_timestamp,
                                                                                              NULL)
                                                        FROM dual),
                                                      - (SELECT pk_sysconfig.get_config('ALERT_EXPIRE_HARVEST',
                                                                                       v.id_institution,
                                                                                       v.id_software)
                                                          FROM dual))
                  FROM dual) <
               (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL, v.id_institution, NULL), v.dt_record, NULL)
                  FROM dual)
           AND v.dt_record < (SELECT pk_date_utils.add_days_to_tstz(current_timestamp,
                                                                    - (pk_sysconfig.get_config('ALERT_HARVEST_TIMEOUT',
                                                                                              v.id_institution,
                                                                                              v.id_software) / (24 * 60)))
                                FROM dual)
           AND v.id_episode = e.id_episode
           AND e.id_patient = p.id_patient
           AND e.id_episode = ei.id_episode
           AND ei.id_room = r.id_room
           AND ((v.id_professional = sys_context('ALERT_CONTEXT', 'i_prof') AND v.id_professional = vpa.id_professional AND
               vpa.id_clinical_service = v.id_clinical_service))
           AND NOT EXISTS
         (SELECT 1
                  FROM sys_alert_read sar
                 WHERE sar.id_sys_alert_event = v.id_sys_alert_event
                   AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                   AND (SELECT pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                                             v.id_sys_alert,
                                                             NULL)
                          FROM dual) = 'N')
        UNION ALL
        SELECT v.id_sys_alert_event,
               v.id_record,
               v.id_episode,
               v.id_institution,
               v.dt_record,
               v.id_sys_alert,
               v.replace1,
               v.id_software,
               p.id_patient,
               ei.id_schedule,
               p.gender,
               r.desc_room_abbreviation,
               r.desc_room,
               r.code_room,
               r.code_abbreviation,
               e.dt_begin_tstz,
               ei.triage_acuity,
               ei.triage_rank_acuity,
               ei.dt_first_obs_tstz,
               ei.id_triage_color,
               id_prof_order
          FROM sys_alert_event v, episode e, epis_info ei, patient p, room r, v_prof_alerts vpa
         WHERE v.id_sys_alert = 4
           AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND v.flg_visible = 'Y'
           AND (SELECT pk_date_utils.add_days_to_tstz((SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                           v.id_institution,
                                                                                                           NULL),
                                                                                              current_timestamp,
                                                                                              NULL)
                                                        FROM dual),
                                                      - (SELECT pk_sysconfig.get_config('ALERT_EXPIRE_HARVEST',
                                                                                       v.id_institution,
                                                                                       v.id_software)
                                                          FROM dual))
                  FROM dual) <
               (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL, v.id_institution, NULL), v.dt_record, NULL)
                  FROM dual)
           AND v.dt_record < (SELECT pk_date_utils.add_days_to_tstz(current_timestamp,
                                                                    - (pk_sysconfig.get_config('ALERT_HARVEST_TIMEOUT',
                                                                                              v.id_institution,
                                                                                              v.id_software) / (24 * 60)))
                                FROM dual)
           AND v.id_episode = e.id_episode
           AND e.id_patient = p.id_patient
           AND e.id_episode = ei.id_episode
           AND ei.id_room = r.id_room
           AND (v.id_clinical_service IS NOT NULL AND vpa.id_clinical_service = v.id_clinical_service AND
               vpa.id_professional = sys_context('ALERT_CONTEXT', 'i_prof'))
           AND NOT EXISTS
         (SELECT 1
                  FROM sys_alert_read sar
                 WHERE sar.id_sys_alert_event = v.id_sys_alert_event
                   AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                   AND (SELECT pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                                             v.id_sys_alert,
                                                             NULL)
                          FROM dual) = 'N')
        UNION ALL
        SELECT v.id_sys_alert_event,
               v.id_record,
               v.id_episode,
               v.id_institution,
               v.dt_record,
               v.id_sys_alert,
               v.replace1,
               v.id_software,
               p.id_patient,
               ei.id_schedule,
               p.gender,
               r.desc_room_abbreviation,
               r.desc_room,
               r.code_room,
               r.code_abbreviation,
               e.dt_begin_tstz,
               ei.triage_acuity,
               ei.triage_rank_acuity,
               ei.dt_first_obs_tstz,
               ei.id_triage_color,
               id_prof_order
          FROM sys_alert_event v, episode e, epis_info ei, patient p, room r, v_prof_alerts vpa
         WHERE v.id_sys_alert = 4
           AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND v.flg_visible = 'Y'
           AND (SELECT pk_date_utils.add_days_to_tstz((SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                           v.id_institution,
                                                                                                           NULL),
                                                                                              current_timestamp,
                                                                                              NULL)
                                                        FROM dual),
                                                      - (SELECT pk_sysconfig.get_config('ALERT_EXPIRE_HARVEST',
                                                                                       v.id_institution,
                                                                                       v.id_software)
                                                          FROM dual))
                  FROM dual) <
               (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL, v.id_institution, NULL), v.dt_record, NULL)
                  FROM dual)
           AND v.dt_record < (SELECT pk_date_utils.add_days_to_tstz(current_timestamp,
                                                                    - (pk_sysconfig.get_config('ALERT_HARVEST_TIMEOUT',
                                                                                              v.id_institution,
                                                                                              v.id_software) / (24 * 60)))
                                FROM dual)
           AND v.id_episode = e.id_episode
           AND e.id_patient = p.id_patient
           AND e.id_episode = ei.id_episode
           AND ei.id_room = r.id_room
           AND ((v.id_professional = sys_context('ALERT_CONTEXT', 'i_prof') AND v.id_professional = vpa.id_professional AND
               vpa.id_clinical_service = v.id_clinical_service))
           AND NOT EXISTS
         (SELECT 1
                  FROM sys_alert_read sar
                 WHERE sar.id_sys_alert_event = v.id_sys_alert_event
                   AND sar.id_professional = sys_context('ALERT_CONTEXT', 'i_prof')
                   AND (SELECT pk_alerts.get_config_flg_read(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                          sys_context('ALERT_CONTEXT', 'i_software')),
                                                             v.id_sys_alert,
                                                             NULL)
                          FROM dual) = 'N')
           AND pk_alerts.check_if_alert_expired(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                                v.dt_creation,
                                                v.id_sys_alert) > 0) t;
