CREATE OR REPLACE VIEW v_rehab_appointment AS
WITH aux AS
 (SELECT x1.sys_lang sys_lang,
         x1.sys_prof_id sys_prof_id,
         x1.sys_prof_institution sys_prof_institution,
         x1.sys_prof_software sys_prof_software,
         x1.sys_lprof sys_lprof,
         alert_context('l_flg_sch_type_cr') sys_flg_sch_type_cr,
         alert_context('l_scfg_rehab_needs_sch') sys_scfg_rehab_needs_sch,
         alert_context('l_show_med_disch') sys_show_med_disch,
         alert_context('l_epis_type_rehab_ap') sys_epis_type_rehab_ap,
         CAST(pk_date_utils.trunc_insttimezone(x1.sys_lprof,
                                               pk_date_utils.get_string_tstz(x1.sys_lang,
                                                                             x1.sys_lprof,
                                                                             alert_context('l_dt_begin'),
                                                                             '')) AS TIMESTAMP WITH LOCAL TIME ZONE) sys_dt_begin,
         CAST(pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(x1.sys_lprof,
                                                                              pk_date_utils.get_string_tstz(x1.sys_lang,
                                                                                                            x1.sys_lprof,
                                                                                                            alert_context('l_dt_end'),
                                                                                                            '')),
                                             1) AS TIMESTAMP WITH LOCAL TIME ZONE) sys_dt_end
    FROM (SELECT alert_context('l_lang') sys_lang,
                 profissional(alert_context('l_prof_id'),
                              alert_context('l_prof_institution'),
                              alert_context('l_prof_software')) sys_lprof,
                 alert_context('l_prof_id') sys_prof_id,
                 alert_context('l_prof_institution') sys_prof_institution,
                 alert_context('l_prof_software') sys_prof_software
            FROM dual) x1)
SELECT /*+ index(sp sop_search02_idx) */
 s.id_group s_id_group,
 sg.flg_contact_type,
 s.id_schedule,
 e.id_patient,
 e.id_episode,
 re.id_episode_rehab,
 e.id_visit,
 e.id_epis_type,
 spo.id_professional id_resp_professional,
 NULL id_resp_rehab_group,
 re.dt_creation,
 s.dt_begin_tstz,
 (SELECT pk_rehab.get_rehab_app_status(alert_context('l_lang'),
                                       profissional(alert_context('l_prof_id'),
                                                    alert_context('l_prof_institution'),
                                                    alert_context('l_prof_software')),
                                       e.id_patient,
                                       re.flg_status)
    FROM dual) flg_status,
 1442 shortcut,
 sp.id_epis_type id_schedule_type,
 s.dt_schedule_tstz,
 (SELECT se.code_sch_event
    FROM sch_event se
   WHERE se.id_sch_event = s.id_sch_event) code_rehab_session_type,
 NULL abbreviation,
 NULL code_department,
 NULL id_room,
 NULL desc_room_abbreviation,
 NULL code_abbreviation,
 NULL code_room,
 NULL desc_room,
 NULL code_bed,
 NULL desc_bed,
 re.id_rehab_epis_encounter,
 NULL id_rehab_sch_need,
 NULL id_rehab_schedule,
 ei.id_software,
 ei.id_professional,
 e.flg_status e_flg_status,
 s.id_schedule id_lock_uq_value,
 'REHAB_GRID_SCHED' lock_func,
 'A' grid_workflow_icon,
 'A' grid_workflow_icon_status,
 'A' flg_type,
 (SELECT pk_message.get_message(alert_context('l_lang'),
                                profissional(alert_context('l_prof_id'),
                                             alert_context('l_prof_institution'),
                                             alert_context('l_prof_software')),
                                'REHAB_T148')
    FROM dual) desc_schedule_type,
 e.flg_ehr,
 coalesce(ei.dt_init, ei.dt_first_obs_tstz) dt_init
  FROM schedule_outp sp
  JOIN schedule s
    ON s.id_schedule = sp.id_schedule
  JOIN aux
    ON aux.sys_prof_institution = s.id_instit_requested
  JOIN sch_group sg
    ON sg.id_schedule = s.id_schedule
  JOIN epis_info ei
    ON s.id_schedule = ei.id_schedule
  JOIN epis_type et
    ON sp.id_epis_type = et.id_epis_type
  JOIN episode e
    ON ei.id_episode = e.id_episode
  LEFT JOIN sch_prof_outp spo
    ON spo.id_schedule_outp = sp.id_schedule_outp
  LEFT JOIN rehab_epis_encounter re
    ON re.id_episode_origin = e.id_episode
   AND re.flg_rehab_workflow_type = 'A'
  JOIN rehab_environment r
    ON r.id_epis_type = e.id_epis_type
   AND r.id_institution IN (0, aux.sys_prof_institution)
   AND r.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                    FROM rehab_environment_prof rep
                                   WHERE rep.id_professional = aux.sys_prof_id)
 WHERE ((s.flg_sch_type = aux.sys_flg_sch_type_cr AND aux.sys_flg_sch_type_cr IS NOT NULL) OR
       aux.sys_flg_sch_type_cr IS NULL)
   AND s.flg_status NOT IN ('V', 'C')
   AND s.id_instit_requested = aux.sys_prof_institution
   AND sp.id_software = aux.sys_prof_software
   AND ((sp.id_epis_type = aux.sys_epis_type_rehab_ap AND aux.sys_epis_type_rehab_ap <> 0) OR
       aux.sys_epis_type_rehab_ap = 0)
   AND sp.dt_target_tstz BETWEEN aux.sys_dt_begin AND aux.sys_dt_end
   AND (aux.sys_show_med_disch = 'Y' OR
       (aux.sys_show_med_disch = 'N' AND (SELECT pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)
                                             FROM dual) != 'D'))
UNION ALL
SELECT /*+ index(sp sop_dttargettstz_i) */
 s.id_group s_id_group,
 sg.flg_contact_type,
 s.id_schedule,
 e.id_patient,
 e.id_episode,
 e.id_episode id_episode_rehab,
 e.id_visit,
 e.id_epis_type,
 spo.id_professional id_resp_professional,
 NULL id_resp_rehab_group,
 e.dt_creation dt_creation,
 s.dt_begin_tstz,
 (SELECT pk_rehab.get_rehab_app_status(aux.sys_lang,
                                       aux.sys_lprof,
                                       e.id_patient,
                                       decode(sp.flg_state, 'M', 'X', sp.flg_state))
    FROM dual) flg_status,
 1442 shortcut,
 sp.id_epis_type id_schedule_type,
 s.dt_schedule_tstz,
 NULL code_rehab_session_type,
 NULL abbreviation,
 NULL code_department,
 NULL id_room,
 NULL desc_room_abbreviation,
 NULL code_abbreviation,
 NULL code_room,
 NULL desc_room,
 NULL code_bed,
 NULL desc_bed,
 NULL id_rehab_epis_encounter,
 NULL id_rehab_sch_need,
 NULL id_rehab_schedule,
 ei.id_software,
 ei.id_professional,
 e.flg_status e_flg_status,
 s.id_schedule id_lock_uq_value,
 'REHAB_GRID_SCHED' lock_func,
 'H' grid_workflow_icon,
 'H' grid_workflow_icon_status,
 'H' flg_type,
 (SELECT pk_message.get_message(aux.sys_lang, aux.sys_lprof, 'REHAB_T148')
    FROM dual) desc_schedule_type,
 e.flg_ehr,
 coalesce(ei.dt_init, ei.dt_first_obs_tstz) dt_init
  FROM schedule_outp sp
  JOIN schedule s
    ON s.id_schedule = sp.id_schedule
  JOIN aux
    ON s.id_instit_requested = aux.sys_prof_institution
  JOIN sch_group sg
    ON sg.id_schedule = s.id_schedule
  JOIN epis_info ei
    ON s.id_schedule = ei.id_schedule
  JOIN epis_type et
    ON sp.id_epis_type = et.id_epis_type
  JOIN episode e
    ON ei.id_episode = e.id_episode
  LEFT JOIN sch_prof_outp spo
    ON spo.id_schedule_outp = sp.id_schedule_outp
 WHERE 0 = 0
 AND s.flg_status NOT IN ('V', 'C')
 AND s.id_instit_requested = aux.sys_prof_institution
 AND sp.id_epis_type = 50
 AND (NOT (e.flg_status = 'I' AND e.flg_ehr = 'S'))
 AND sp.dt_target_tstz BETWEEN aux.sys_dt_begin AND aux.sys_dt_end
 AND (aux.sys_show_med_disch = 'Y' OR
 (aux.sys_show_med_disch = 'N' AND (SELECT pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)
                                           FROM dual) != 'D'));
