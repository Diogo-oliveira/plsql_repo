CREATE OR REPLACE VIEW V_SYS_ALERT_150 AS
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 v.id_episode,
 v.id_institution,
 v.id_professional id_prof,
 (SELECT pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                                         sys_context('ALERT_CONTEXT', 'i_software')),
                                            v.dt_record,
                                            'YYYYMMDDHH24MISS')
    FROM dual) dt_req,
 decode(instr((SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record)
                FROM dual),
              ':'),
        0,
        (SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record)
           FROM dual),
        (SELECT pk_date_utils.get_elapsed_sysdate_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), v.dt_record)
           FROM dual) || ' ' || (SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'i_lang'), 'ALERT_LIST_T003')
                                   FROM dual)) TIME,
 (SELECT pk_alerts.get_alert_message(sys_context('ALERT_CONTEXT', 'i_lang'),
                                     profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                  sys_context('ALERT_CONTEXT', 'i_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_software')),
                                     v.id_sys_alert,
                                     v.replace1,
                                     pk_sysconfig.get_config('ALERT_TAKE_TIMEOUT1', v.id_institution, v.id_software),
                                     'N')
    FROM dual) message,
 NULL id_room,
 p.id_patient,
 (SELECT pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                              sys_context('ALERT_CONTEXT', 'i_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_software')),
                                 e.id_patient,
                                 v.id_episode,
                                 ei.id_schedule)
    FROM dual) name_pat,
 (SELECT pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software')),
                                         e.id_patient)
    FROM dual) pat_ndo,
 (SELECT pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                            profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                                         sys_context('ALERT_CONTEXT', 'i_software')),
                                            e.id_patient)
    FROM dual) pat_nd_icon,
  (SELECT pk_patphoto.get_pat_photo(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                                sys_context('ALERT_CONTEXT', 'i_software')),
                                   e.id_patient,
                                   v.id_episode,
                                   NULL)
    FROM dual) photo,
 p.gender,
 (SELECT pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                                p.id_patient,
                                sys_context('ALERT_CONTEXT', 'i_institution'),
                                sys_context('ALERT_CONTEXT', 'i_software'))
    FROM dual) pat_age,
 coalesce(r.desc_room_abbreviation,
          (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_abbreviation)
             FROM dual),
          r.desc_room,
          (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'), r.code_room)
             FROM dual)) desc_room,
 (SELECT pk_date_utils.get_elapsed_tsz(sys_context('ALERT_CONTEXT', 'i_lang'), e.dt_begin_tstz, current_timestamp)
    FROM dual) date_send,
 (SELECT pk_edis_grid.get_complaint_grid(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         sys_context('ALERT_CONTEXT', 'i_institution'),
                                         sys_context('ALERT_CONTEXT', 'i_software'),
                                         e.id_episode)
    FROM dual) desc_epis_anamnesis,
 ei.triage_acuity acuity,
 ei.triage_rank_acuity rank_acuity,
 NULL id_schedule,
 (SELECT pk_alerts.get_alerts_shortcut(profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                    sys_context('ALERT_CONTEXT', 'i_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_software')),
                                       v.id_sys_alert)
    FROM dual) id_sys_shortcut,
 v.id_record id_reg_det,
 v.id_sys_alert,
 (SELECT pk_episode.get_epis_dt_first_obs(ei.id_episode, ei.dt_first_obs_tstz, NULL, 'Y')
    FROM dual) dt_first_obs_tstz,
 (SELECT pk_fast_track.get_fast_track_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_software')),
                                           e.id_episode,
                                           NULL,
                                           ei.id_triage_color,
                                           NULL,
                                           NULL)
    FROM dual) fast_track_icon,
 decode(ei.triage_acuity, '0xFFFFFF', '0x787864', '0xFFFFFF') fast_track_color,
 'A' fast_track_status,
 (SELECT pk_edis_triage.get_epis_esi_level(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                        sys_context('ALERT_CONTEXT', 'i_institution'),
                                                        sys_context('ALERT_CONTEXT', 'i_software')),
                                           e.id_episode,
                                           ei.id_triage_color)
    FROM dual) esi_level,
 (SELECT pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                         profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                      sys_context('ALERT_CONTEXT', 'i_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_software')),
                                         e.id_patient,
                                         v.id_episode)
    FROM dual) name_pat_sort,
 (SELECT pk_hand_off_api.get_resp_icons(sys_context('ALERT_CONTEXT', 'i_lang'),
                                        profissional(sys_context('ALERT_CONTEXT', 'i_prof'),
                                                     sys_context('ALERT_CONTEXT', 'i_institution'),
                                                     sys_context('ALERT_CONTEXT', 'i_software')),
                                        v.id_episode,
                                        sys_context('ALERT_CONTEXT', 'l_hand_off_type'))
    FROM dual) resp_icons,
 id_prof_order
  FROM sys_alert_event v
  JOIN episode e
    ON v.id_episode = e.id_episode
  JOIN epis_info ei
    ON e.id_episode = ei.id_episode
  JOIN patient p
    ON e.id_patient = p.id_patient
  JOIN room r
    ON ei.id_room = r.id_room
 WHERE v.id_sys_alert = 150
   AND v.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
   AND v.flg_visible = 'Y'
   AND (SELECT pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(profissional(NULL, v.id_institution, NULL),
                                                                               current_timestamp,
                                                                               NULL),
                                              -pk_sysconfig.get_config('ALERT_EXPIRE_TAKE',
                                                                       v.id_institution,
                                                                       v.id_software))
          FROM dual) < pk_date_utils.trunc_insttimezone(profissional(NULL, v.id_institution, NULL), v.dt_record, NULL)
   AND v.dt_record < (SELECT pk_date_utils.add_days_to_tstz(current_timestamp,
                                                            - (pk_sysconfig.get_config('ALERT_TAKE_TIMEOUT1',
                                                                                      v.id_institution,
                                                                                      v.id_software) / (24 * 60)))
                        FROM dual)
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
   AND (sys_context('ALERT_CONTEXT', 'i_prof') IN
       (SELECT DISTINCT pdcs.id_professional
           FROM dep_clin_serv dcs, prof_dep_clin_serv pdcs, prof_cat pc, category c
          WHERE dcs.id_clinical_service = v.id_clinical_service
            AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
            AND pdcs.flg_status = 'S'
            AND pc.id_professional = pdcs.id_professional
            AND pc.id_institution = v.id_institution
            AND c.id_category = pc.id_category
            AND c.flg_type IN ('D', 'N')));
