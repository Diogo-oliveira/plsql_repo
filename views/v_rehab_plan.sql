CREATE OR REPLACE VIEW v_rehab_plan AS
WITH aux AS
 (SELECT x1.sys_lang sys_lang,
         x1.sys_prof_id sys_prof_id,
         x1.sys_prof_institution sys_prof_institution,
         x1.sys_prof_software sys_prof_software,
         x1.sys_lprof sys_lprof,
         alert_context('l_scfg_rehab_needs_sch') sys_scfg_rehab_needs_sch,
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
                                             1) AS TIMESTAMP WITH LOCAL TIME ZONE) sys_dt_end,
         CAST(pk_date_utils.trunc_insttimezone(x1.sys_lprof, current_timestamp) AS TIMESTAMP WITH LOCAL TIME ZONE) sys_today1,
         CAST(pk_date_utils.trunc_insttimezone(x1.sys_lprof, current_timestamp) AS TIMESTAMP WITH LOCAL TIME ZONE) +
         numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND') sys_today9
    FROM (SELECT alert_context('l_lang') sys_lang,
                 profissional(alert_context('l_prof_id'),
                              alert_context('l_prof_institution'),
                              alert_context('l_prof_software')) sys_lprof,
                 alert_context('l_prof_id') sys_prof_id,
                 alert_context('l_prof_institution') sys_prof_institution,
                 alert_context('l_prof_software') sys_prof_software
            FROM dual) x1)
SELECT NULL s_id_group,
       NULL flg_contact_type,
       NULL id_schedule,
       e.id_patient,
       e.id_episode,
       coalesce(re.id_episode_rehab, e.id_episode) id_episode_rehab,
       e.id_visit,
       e.id_epis_type,
       re.id_prof_creation id_resp_professional,
       NULL id_resp_rehab_group,
       rep.dt_rehab_epis_plan dt_creation,
       NULL dt_begin_tstz,
       nvl(re.flg_status, 'E') flg_status,
       1442 shortcut,
       1 id_schedule_type,
       NULL dt_schedule_tstz,
       'REHAB_M050' code_rehab_session_type,
       dpt.abbreviation,
       dpt.code_department,
       ro.id_room,
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.desc_room,
       bd.code_bed,
       bd.desc_bed,
       NULL id_rehab_epis_encounter,
       NULL id_rehab_sch_need,
       NULL id_rehab_schedule,
       ei.id_software,
       ei.id_professional,
       e.flg_status e_flg_status,
       rep.id_rehab_epis_plan id_lock_uq_value,
       'REHAB_GRID_PLAN' lock_func,
       'W' grid_workflow_icon,
       'E' grid_workflow_icon_status,
       'W' flg_type,
       (SELECT pk_message.get_message(aux.sys_lang, aux.sys_lprof, 'REHAB_T147')
          FROM dual) desc_schedule_type
  FROM rehab_epis_plan rep
  JOIN episode e
    ON (e.id_episode = (SELECT ree.id_episode_origin
                          FROM rehab_epis_encounter ree
                         WHERE ree.id_episode_rehab = rep.id_episode) AND
       e.id_institution = alert_context('l_prof_institution'))
  JOIN aux
    ON aux.sys_prof_institution = e.id_institution
  JOIN rehab_environment r
    ON r.id_epis_type = e.id_epis_type
   AND r.id_institution IN (0, aux.sys_prof_institution)
   AND r.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                    FROM rehab_environment_prof rep
                                   WHERE rep.id_professional = aux.sys_prof_id)
  LEFT JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = ei.id_bed
  LEFT JOIN room ro
    ON ro.id_room = bd.id_room
  LEFT JOIN department dpt
    ON dpt.id_department = ro.id_department
  LEFT JOIN rehab_epis_encounter re
    ON (re.id_episode_origin = e.id_episode AND re.dt_creation BETWEEN aux.sys_dt_begin AND aux.sys_dt_end)
 WHERE 0 = 0
   AND rep.flg_status = 'O'
      --Non scheduled plans should only appear on the Today grid
   AND aux.sys_dt_begin BETWEEN aux.sys_today1 AND aux.sys_today9
   AND e.flg_status NOT IN ('I', 'C')
UNION
SELECT NULL s_id_group,
       NULL flg_contact_type,
       NULL id_schedule,
       e.id_patient,
       e.id_episode,
       coalesce(re.id_episode_rehab, e.id_episode) id_episode_rehab,
       e.id_visit,
       e.id_epis_type,
       re.id_prof_creation id_resp_professional,
       NULL id_resp_rehab_group,
       rep.dt_rehab_epis_plan dt_creation,
       NULL dt_begin_tstz,
       nvl(re.flg_status, 'E') flg_status,
       1442 shortcut,
       1 id_schedule_type,
       NULL dt_schedule_tstz,
       'REHAB_M050' code_rehab_session_type,
       dpt.abbreviation,
       dpt.code_department,
       ro.id_room,
       ro.desc_room_abbreviation,
       ro.code_abbreviation,
       ro.code_room,
       ro.desc_room,
       bd.code_bed,
       bd.desc_bed,
       re.id_rehab_epis_encounter,
       re.id_rehab_sch_need id_rehab_sch_need,
       NULL id_rehab_schedule,
       ei.id_software,
       ei.id_professional,
       e.flg_status e_flg_status,
       rep.id_rehab_epis_plan id_lock_uq_value,
       'REHAB_GRID_PLAN' lock_func,
       'W' grid_workflow_icon,
       'E' grid_workflow_icon_status,
       'W' flg_type,
       (SELECT pk_message.get_message(aux.sys_lang, aux.sys_lprof, 'REHAB_T147')
          FROM dual) desc_schedule_type
  FROM rehab_epis_plan rep
  JOIN episode e
    ON (e.id_episode = rep.id_episode AND e.id_institution = alert_context('l_prof_institution'))
  JOIN aux
    ON aux.sys_prof_institution = e.id_institution
  JOIN rehab_environment r
    ON r.id_epis_type = e.id_epis_type
 AND r.id_institution IN (0, aux.sys_prof_institution)
 AND r.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                  FROM rehab_environment_prof rep
                                 WHERE rep.id_professional = aux.sys_prof_id)
  LEFT JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = ei.id_bed
  LEFT JOIN room ro
    ON ro.id_room = bd.id_room
  LEFT JOIN department dpt
    ON dpt.id_department = ro.id_department
  LEFT JOIN rehab_epis_encounter re
    ON (re.id_episode_origin = e.id_episode AND re.dt_creation BETWEEN aux.sys_dt_begin AND aux.sys_dt_end)
 WHERE 0 = 0
 AND rep.flg_status = 'O'
--Non scheduled plans should only appear on the Today grid
 AND aux.sys_dt_begin BETWEEN aux.sys_today1 AND aux.sys_today9
 AND e.flg_status NOT IN ('I', 'C');
