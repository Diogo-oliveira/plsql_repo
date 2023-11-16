CREATE OR REPLACE VIEW V_REHAB_PLAN_MY AS
SELECT NULL s_id_group,
       NULL flg_contact_type,
       -1 id_schedule,
       e.id_patient,
       e.id_episode,
       re.id_episode_rehab,
       e.id_visit,
       e.id_epis_type,
       rep.id_prof_create id_resp_professional,
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
       NULL id_rehab_sch_need,
       NULL id_rehab_schedule,
       ei.id_software,
       ei.id_professional,
       e.flg_status e_flg_status,
       rep.id_rehab_epis_plan id_lock_uq_value,
       'REHAB_GRID_SCHED' lock_func,
       'W' grid_workflow_icon,
       'E' grid_workflow_icon_status,
       'W' flg_type,
       (SELECT pk_message.get_message(alert_context('l_lang'),
                                      profissional(alert_context('l_prof_id'),
                                                   alert_context('l_prof_institution'),
                                                   alert_context('l_prof_software')),
                                      'REHAB_T147')
          FROM dual) desc_schedule_type
  FROM rehab_epis_plan rep
  JOIN rehab_epis_plan_team rept
    ON (rept.id_rehab_epis_plan = rep.id_rehab_epis_plan AND rept.flg_status = 'Y')
  JOIN prof_cat pc
    ON (rept.id_prof_cat = pc.id_prof_cat AND pc.id_professional = sys_context('ALERT_CONTEXT', 'l_prof_id'))
  JOIN episode e
    ON (e.id_episode = (SELECT ree.id_episode_origin
                          FROM rehab_epis_encounter ree
                         WHERE ree.id_episode_rehab = rep.id_episode) AND
       e.id_institution = alert_context('l_prof_institution'))
  JOIN rehab_environment r
    ON r.id_epis_type = e.id_epis_type
   AND r.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
   AND r.id_rehab_environment IN
       (SELECT rep.id_rehab_environment
          FROM rehab_environment_prof rep
         WHERE rep.id_professional = sys_context('ALERT_CONTEXT', 'l_prof_id'))
  LEFT JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = ei.id_bed
  LEFT JOIN room ro
    ON ro.id_room = bd.id_room
  LEFT JOIN department dpt
    ON dpt.id_department = ro.id_department
  LEFT JOIN rehab_epis_encounter re
    ON (re.id_episode_origin = e.id_episode AND
       re.dt_creation BETWEEN CAST(sys_context('ALERT_CONTEXT', 'l_dt_begin') AS TIMESTAMP WITH LOCAL TIME ZONE) AND
       CAST(sys_context('ALERT_CONTEXT', 'l_dt_end') AS TIMESTAMP WITH LOCAL TIME ZONE))
 WHERE rep.flg_status = 'O'
      --Non scheduled plans should only appear on the Today grid
   AND CAST(sys_context('ALERT_CONTEXT', 'l_dt_begin') AS TIMESTAMP WITH LOCAL TIME ZONE) =
       CAST(sys_context('ALERT_CONTEXT', 'l_dt_today') AS TIMESTAMP WITH LOCAL TIME ZONE)
   AND e.flg_status = 'A'
UNION ALL
SELECT NULL s_id_group,
       NULL flg_contact_type,
       -1 id_schedule,
       e.id_patient,
       e.id_episode,
       re.id_episode_rehab,
       e.id_visit,
       e.id_epis_type,
       rep.id_prof_create id_resp_professional,
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
       NULL id_rehab_sch_need,
       NULL id_rehab_schedule,
       ei.id_software,
       ei.id_professional,
       e.flg_status e_flg_status,
       rep.id_rehab_epis_plan id_lock_uq_value,
       'REHAB_GRID_SCHED' lock_func,
       'W' grid_workflow_icon,
       'E' grid_workflow_icon_status,
       'W' flg_type,
       (SELECT pk_message.get_message(alert_context('l_lang'),
                                      profissional(alert_context('l_prof_id'),
                                                   alert_context('l_prof_institution'),
                                                   alert_context('l_prof_software')),
                                      'REHAB_T147')
          FROM dual) desc_schedule_type
  FROM rehab_epis_plan rep
  JOIN rehab_epis_plan_team rept
    ON (rept.id_rehab_epis_plan = rep.id_rehab_epis_plan AND rept.flg_status = 'Y')
  JOIN prof_cat pc
    ON (rept.id_prof_cat = pc.id_prof_cat AND pc.id_professional = sys_context('ALERT_CONTEXT', 'l_prof_id'))
  JOIN episode e
    ON (e.id_episode = rep.id_episode AND e.id_institution = alert_context('l_prof_institution'))
  JOIN rehab_environment r
    ON r.id_epis_type = e.id_epis_type
   AND r.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
   AND r.id_rehab_environment IN
       (SELECT rep.id_rehab_environment
          FROM rehab_environment_prof rep
         WHERE rep.id_professional = sys_context('ALERT_CONTEXT', 'l_prof_id'))
  LEFT JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = ei.id_bed
  LEFT JOIN room ro
    ON ro.id_room = bd.id_room
  LEFT JOIN department dpt
    ON dpt.id_department = ro.id_department
  LEFT JOIN rehab_epis_encounter re
    ON (re.id_episode_origin = e.id_episode AND
       re.dt_creation BETWEEN CAST(sys_context('ALERT_CONTEXT', 'l_dt_begin') AS TIMESTAMP WITH LOCAL TIME ZONE) AND
       CAST(sys_context('ALERT_CONTEXT', 'l_dt_end') AS TIMESTAMP WITH LOCAL TIME ZONE))
 WHERE rep.flg_status = 'O'
      --Non scheduled plans should only appear on the Today grid
   AND CAST(sys_context('ALERT_CONTEXT', 'l_dt_begin') AS TIMESTAMP WITH LOCAL TIME ZONE) =
       CAST(sys_context('ALERT_CONTEXT', 'l_dt_today') AS TIMESTAMP WITH LOCAL TIME ZONE)
   AND e.flg_status = 'A';
