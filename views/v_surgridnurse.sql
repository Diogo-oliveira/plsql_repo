CREATE OR REPLACE VIEW v_surgridnurse AS
SELECT s.id_schedule,
       -- cmf
        s.dt_target_tstz,
       -- cmf
       s.id_episode,
       decode(h.flg_urgency, 'Y', 'U', decode(s.id_sched_sr_parent, NULL, 'N', 'R')) flg_rescheduled, --Indica se a cirurgia foi reagendada para ter uma visualização gráfica diferente
       pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) hour_interv_preview_send,
       pk_date_utils.date_char_hour_tsz(i_lang, s.dt_interv_preview_tstz, i_prof.institution, i_prof.software) hour_interv_preview,
       nvl(pk_date_utils.date_send_tsz(i_lang, st.dt_interv_start_tstz, i_prof), 0) hour_interv_start,
       nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_sched_room,
       pk_sysdomain.get_img(i_lang, 'SR_ROOM_STATUS.FLG_STATUS', nvl(m.flg_status, 'F')) room_status,
       nvl(m.flg_status, 'F') room_status_det,
       r.id_room,
       pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender,
       pk_patient.get_pat_age(i_lang, p.id_patient, i_prof.institution, i_prof.software) pat_age,
       pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, epis.id_episode, h.id_schedule) photo,
       p.id_patient,
       pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, epis.id_episode, h.id_schedule) pat_name,
       pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, epis.id_episode) name_pat_to_sort,
       pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
       pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
       pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, i_prof, pk_alert_constant.get_no()) desc_intervention,
       pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
       pk_episode.get_epis_room(i_lang, i_prof, epis.id_episode) desc_room,
       pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc) desc_drug_presc,
       pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, PK_GRIDFILTER.get_strings('g_task_exam'), PK_GRIDFILTER.get_strings('l_prof_cat',i_lang, i_prof)) desc_exam_req,
       pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, PK_GRIDFILTER.get_strings('g_task_analysis'), PK_GRIDFILTER.get_strings('l_prof_cat',i_lang,i_prof)) desc_analysis_req,
       pk_grid.convert_grid_task_dates_to_str(i_lang,
                                              i_prof,
                                              pk_grid.get_prioritary_task(i_lang,
                                                                          i_prof,
                                                                          pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                         i_prof,
                                                                                                         epis.id_visit,
                                                                                                         PK_GRIDFILTER.get_strings('g_task_analysis'),
                                                                                                         PK_GRIDFILTER.get_strings('l_prof_cat',i_lang,i_prof)),
                                                                          pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                         i_prof,
                                                                                                         epis.id_visit,
                                                                                                         PK_GRIDFILTER.get_strings('g_task_exam'),
                                                                                                         PK_GRIDFILTER.get_strings('l_prof_cat',i_lang,i_prof)),
                                                                          PK_GRIDFILTER.get_strings('g_analysis_exam_icon_grid_rank'),
                                                                          PK_GRIDFILTER.get_strings('g_cat_type_nurse'))) desc_analysis_exam_req,
       decode(s.id_episode, m.id_episode, nvl(m.flg_status, 'F'), NULL) room_state,
       pk_grid.convert_grid_task_str(i_lang, i_prof, gt.hemo_req) hemo_req_status,
       pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
       --pk_sr_supplies.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
       pk_sysdomain.get_img(i_lang, 'SR_SURGERY_ROOM.FLG_PAT_STATUS', nvl(rec.flg_pat_status, PK_GRIDFILTER.get_strings('g_pat_status_pend'))) pat_status,
       nvl(rec.flg_pat_status, PK_GRIDFILTER.get_strings('g_pat_status_pend')) pat_status_det,
       pk_date_utils.date_send_tsz(i_lang, m.dt_status_tstz, i_prof) dt_room_status,
       pk_date_utils.date_send_tsz(i_lang,
                                   decode(rec.flg_pat_status,
                                          'S',
                                          nvl(st.dt_interv_start_tstz,
                                              (SELECT decode(ps.flg_pat_status,
                                                             PK_GRIDFILTER.get_strings('g_pat_status_l'),
                                                             ps.dt_status_tstz,
                                                             PK_GRIDFILTER.get_strings('g_pat_status_s'),
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
                                                         PK_GRIDFILTER.get_strings('g_pat_status_l'),
                                                         ps.dt_status_tstz,
                                                         PK_GRIDFILTER.get_strings('g_pat_status_s'),
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
                                   i_prof) dt_pat_status,
       s.flg_status flg_surg_status,
       pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, PK_GRIDFILTER.get_strings('l_hand_off_type',i_lang,i_prof)) resp_icons,
       decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule),
              pk_alert_constant.get_no(),
              decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                      i_prof,
                                                                                      epis.id_episode,
                                                                                      PK_GRIDFILTER.get_strings('l_prof_cat',i_lang, i_prof),
                                                                                      PK_GRIDFILTER.get_strings('l_hand_off_type',i_lang,i_prof),
                                                                                      pk_alert_constant.get_yes()),
                                                  i_prof.id),
                     -1,
                     pk_alert_constant.get_yes(),
                     pk_alert_constant.get_no()),
              pk_alert_constant.get_no()) prof_follow_add,
       pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) prof_follow_remove,
       pk_sr_clinical_info.get_summary_diagnosis(i_lang, i_prof, s.id_episode) desc_diagnosis,
       (SELECT decode(pt.prof_team_name, NULL, NULL, pt.prof_team_name || chr(10)) ||
               pk_prof_utils.get_name_signature(i_lang, i_prof, td.id_prof_team_leader)
          FROM professional pf, sr_prof_team_det td, prof_team pt
         WHERE td.id_episode = s.id_episode
           AND td.id_professional = td.id_prof_team_leader
           AND td.flg_status = PK_GRIDFILTER.get_strings('g_active')
           AND pf.id_professional = td.id_prof_team_leader
           AND pt.id_prof_team(+) = td.id_prof_team
           AND rownum < 2) prof_name,
       NULL desc_obs,
       '(' || pk_sr_tools.get_epis_team_number(i_lang, i_prof, epis.id_episode) || ')' team_number,
       pk_sr_tools.get_principal_team(i_lang, i_prof, epis.id_episode) desc_team,
       pk_sr_tools.get_team_grid_tooltip(i_lang, i_prof, epis.id_episode) name_prof_tooltip,
	   i_prof i_prof,
	   i_prof.id i_prof_id,
	   epis.flg_status epis_status,
       h.dt_begin_tstz
  FROM schedule_sr s,
       schedule h,
       patient p,
       room r,
       room_scheduled sr,
       sr_surgery_record rec,
       grid_task gt,
       episode epis,
       epis_info ei,
       (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
          FROM room r, sr_room_status s
         WHERE s.id_room(+) = r.id_room
           AND (s.id_sr_room_state = pk_sr_grid.get_last_room_status(s.id_room, PK_GRIDFILTER.get_strings('g_type_room')) OR s.id_sr_room_state IS NULL)) m,
       (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
          FROM sr_surgery_time st, sr_surgery_time_det std
         WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
           AND st.flg_type = PK_GRIDFILTER.get_strings('flg_interv_start')
           AND std.flg_status = PK_GRIDFILTER.get_strings('flg_status_a')) st,
       (SELECT (sys_context('ALERT_CONTEXT', 'i_lang')) i_lang,
               profissional((sys_context('ALERT_CONTEXT', 'i_prof_id')),
                            (sys_context('ALERT_CONTEXT', 'i_institution')),
                            (sys_context('ALERT_CONTEXT', 'i_software'))
                            ) i_prof,
               (sys_context('ALERT_CONTEXT', 'i_institution')) institution,
               (sys_context('ALERT_CONTEXT', 'i_software')) software,
               (sys_context('ALERT_CONTEXT', 'i_prof_id')) id
          FROM dual) i_prof
 WHERE s.id_institution = i_prof.institution
   --AND ei.id_software = i_prof.software
   /*AND  Usar como filtro dinamico
        ((EXISTS (SELECT 1
                   FROM prof_room pr, room r1
                  WHERE pr.id_professional = i_prof.id
                    AND r1.id_room = pr.id_room
                    AND (pr.id_room = r.id_room OR
                        pr.id_room = (SELECT ei.id_room
                                         FROM epis_info ei
                                        WHERE ei.id_episode = epis.id_episode))) AND i_type = g_my_patients) OR
       (i_type = g_all_patients) OR
       (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) = pk_alert_constant.g_yes))*/ 
   AND h.id_schedule = s.id_schedule
   AND p.id_patient = s.id_patient
   AND sr.id_schedule(+) = s.id_schedule
   AND sr.flg_status(+) = PK_GRIDFILTER.get_strings('g_active')
   AND (sr.id_room_scheduled = pk_sr_grid.get_last_room_status(s.id_schedule, PK_GRIDFILTER.get_strings('g_type_sch')) OR sr.id_room_scheduled IS NULL)
   AND r.id_room(+) = sr.id_room
   AND m.id_room(+) = sr.id_room
   AND rec.id_schedule_sr(+) = s.id_schedule_sr
   AND ei.id_schedule(+) = s.id_schedule
   AND epis.id_episode = s.id_episode
   AND gt.id_episode(+) = epis.id_episode
   AND st.id_episode(+) = epis.id_episode
   AND epis.flg_ehr != PK_GRIDFILTER.get_strings('g_flg_ehr')
 ORDER BY s.dt_target_tstz;
