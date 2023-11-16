CREATE OR REPLACE VIEW V_SURGRIDMYPATIENTS AS
SELECT         s.id_schedule,
               s.id_episode,
               decode(h.flg_urgency, 'Y', 'U', decode(s.id_sched_sr_parent, NULL, 'N', 'R')) flg_rescheduled, --Indica se a cirurgia foi reagendada para ter uma visualização gráfica diferente
               pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, profissional(prof.prof_id,prof.institution,prof.software)) hour_interv_preview_send,
               pk_date_utils.date_char_hour_tsz(i_lang,
                                                s.dt_interv_preview_tstz,
                                                prof.institution,
                                                prof.software) hour_interv_preview,
               nvl(pk_date_utils.date_send_tsz(i_lang, st.dt_interv_start_tstz, profissional(prof.prof_id,prof.institution,prof.software)), 0) hour_interv_start,
               nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_sched_room,
               pk_sysdomain.get_img(i_lang, 'SR_ROOM_STATUS.FLG_STATUS', nvl(m.flg_status, 'F')) room_status,
               nvl(m.flg_status, 'F') room_status_det,
               r.id_room,
               pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender,
               pk_patient.get_pat_age(i_lang, p.id_patient, prof.institution, prof.software) pat_age,
               pk_patphoto.get_pat_photo(i_lang, profissional(prof.prof_id,prof.institution,prof.software), p.id_patient, epis.id_episode, s.id_schedule) photo,
               p.id_patient,
               pk_patient.get_pat_name(i_lang, profissional(prof.prof_id,prof.institution,prof.software), p.id_patient, epis.id_episode, s.id_schedule) pat_name,
               pk_patient.get_pat_name_to_sort(i_lang, profissional(prof.prof_id,prof.institution,prof.software), p.id_patient, epis.id_episode) name_pat_to_sort,
               pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
               pk_adt.get_pat_non_disc_options(i_lang, profissional(prof.prof_id,prof.institution,prof.software), p.id_patient) pat_ndo,
               pk_adt.get_pat_non_disclosure_icon(i_lang, profissional(prof.prof_id,prof.institution,prof.software), p.id_patient) pat_nd_icon,
               pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, profissional(prof.prof_id,prof.institution,prof.software), pk_alert_constant.get_no()) desc_intervention,
               pk_date_utils.date_send_tsz(i_lang, current_timestamp, profissional(prof.prof_id,prof.institution,prof.software)) dt_server,
               pk_episode.get_epis_room(i_lang, profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode) desc_room,
               pk_grid.convert_grid_task_dates_to_str(i_lang, profissional(prof.prof_id,prof.institution,prof.software), gt.drug_presc) desc_drug_presc,
               epis.id_visit,
               decode(s.id_episode, m.id_episode, nvl(m.flg_status, 'F'), NULL) room_state,
               pk_grid.convert_grid_task_str(i_lang, profissional(prof.prof_id,prof.institution,prof.software), gt.hemo_req) hemo_req_status,
               nvl(pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode, gt.material_req),'') material_req_status,
               --nvl(pk_sr_supplies.get_surg_supplies_reg(i_lang, profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode, gt.material_req),'') material_req_status,
               rec.flg_pat_status,
               pk_date_utils.date_send_tsz(i_lang, m.dt_status_tstz, profissional(prof.prof_id,prof.institution,prof.software)) dt_room_status,
               pk_date_utils.date_send_tsz(i_lang,
                                           decode(rec.flg_pat_status,
                                                  'S',
                                                  nvl(st.dt_interv_start_tstz,
                                                      (SELECT decode(ps.flg_pat_status,
                                                                     'L', --g_pat_status_l,
                                                                     ps.dt_status_tstz,
                                                                     'S', --g_pat_status_s,
                                                                     ps.dt_status_tstz,
                                                                     NULL) dt_status_tstz
                                                         FROM sr_pat_status ps
                                                        WHERE ps.id_episode = epis.id_episode
                                                          AND ps.flg_pat_status = rec.flg_pat_status
                                                          AND ps.dt_status_tstz =
                                                              (SELECT MAX(ps1.dt_status_tstz)
                                                                 FROM sr_pat_status ps1
                                                                WHERE ps1.id_episode = ps.id_episode
                                                                  AND ps1.flg_pat_status = ps.flg_pat_status))),
                                                  (SELECT decode(ps.flg_pat_status,
                                                                 'L', --g_pat_status_l,
                                                                 ps.dt_status_tstz,
                                                                 'S', --g_pat_status_s,
                                                                 ps.dt_status_tstz,
                                                                 NULL) dt_status_tstz
                                                     FROM sr_pat_status ps
                                                    WHERE ps.id_episode = epis.id_episode
                                                      AND ps.flg_pat_status = rec.flg_pat_status
                                                      AND ps.dt_status_tstz =
                                                          (SELECT MAX(ps1.dt_status_tstz)
                                                             FROM sr_pat_status ps1
                                                            WHERE ps1.id_episode = ps.id_episode
                                                              AND ps1.flg_pat_status = ps.flg_pat_status))),
                                           profissional(prof.prof_id,prof.institution,prof.software)) dt_pat_status,
               s.flg_status flg_surg_status,
               pk_prof_follow.get_follow_episode_by_me(profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode, s.id_schedule) prof_follow_remove,
               pk_sr_tools.get_team_profissional(i_lang, profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode) prof_name,
               pk_hand_off_api.get_resp_icons(i_lang, profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode, pk_gridfilter.get_strings('l_hand_off_type',i_lang, profissional(prof.prof_id,prof.institution,prof.software) )) resp_icons,
               '(' || pk_sr_tools.get_epis_team_number(i_lang, profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode) || ')' team_number,
               pk_sr_tools.get_team_grid_tooltip(i_lang, profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode) name_prof_tooltip,
               decode(pk_prof_follow.get_follow_episode_by_me(profissional(prof.prof_id,prof.institution,prof.software), epis.id_episode, s.id_schedule),
                          pk_alert_constant.get_no(),
                          decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                  profissional(prof.prof_id,prof.institution,prof.software),
                                                                                                  epis.id_episode,
                                                                                                  pk_gridfilter.get_strings('l_prof_cat',i_lang, profissional(prof.prof_id,prof.institution,prof.software)),
                                                                                                  pk_gridfilter.get_strings('l_hand_off_type',i_lang, profissional(prof.prof_id,prof.institution,prof.software) ),
                                                                                                  pk_alert_constant.get_yes()),
                                                              prof_id),
                                 -1,
                                 pk_alert_constant.get_yes(),
                                 pk_alert_constant.get_no()),
                          pk_alert_constant.get_no()) prof_follow_add,
               NULL desc_obs,
               s.dt_target_tstz,
               prof.prof_id,
               prof.institution,
               prof.software,
               prof.i_lang,
               ei.id_dep_clin_serv,
               pk_sr_clinical_info.get_summary_diagnosis(i_lang, profissional(prof.prof_id, prof.institution, prof.software ), s.id_episode) desc_diagnosis,
               pk_sr_tools.get_principal_team(i_lang, profissional(prof.prof_id, prof.institution, prof.software ), s.id_episode) desc_team
               ,epis.flg_status epis_status
			   ,r.id_room epis_id_room
          FROM schedule_sr s,
               schedule h,
               patient p,
               room r,
               institution i,
               room_scheduled sr,
               sr_surgery_record rec,
               grid_task gt,
               episode epis,
               epis_info ei,
               (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
                  FROM room r, sr_room_status s
                 WHERE s.id_room(+) = r.id_room
                   AND (s.id_sr_room_state = pk_sr_grid.get_last_room_status(s.id_room, 'R') OR--g_type_room) OR
                        s.id_sr_room_state IS NULL)) m,
               (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
                  FROM sr_surgery_time st, sr_surgery_time_det std
                 WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
                   AND st.flg_type = 'IC'--flg_interv_start
                   AND std.flg_status = 'A') st,--flg_status_a) st,
               (SELECT (sys_context('ALERT_CONTEXT', 'i_lang')) i_lang,
                       (sys_context('ALERT_CONTEXT', 'i_institution')) institution,
                       (sys_context('ALERT_CONTEXT', 'i_software')) software,
                       (sys_context('ALERT_CONTEXT', 'i_prof_id')) prof_id
                  FROM dual) prof
         WHERE s.id_institution = prof.institution
           AND h.id_schedule = s.id_schedule
           AND p.id_patient = s.id_patient
           AND sr.id_schedule(+) = s.id_schedule
           AND (sr.id_room_scheduled = pk_sr_grid.get_last_room_status(s.id_schedule, 'S') OR
               sr.id_room_scheduled IS NULL)
           AND r.id_room(+) = sr.id_room
           AND m.id_room(+) = sr.id_room
           AND i.id_institution = s.id_institution
           AND rec.id_schedule_sr(+) = s.id_schedule_sr
           AND epis.id_episode = s.id_episode
           AND epis.id_episode = ei.id_episode
           AND gt.id_episode(+) = epis.id_episode
           AND st.id_episode(+) = epis.id_episode
           AND epis.flg_ehr != 'E'
;
