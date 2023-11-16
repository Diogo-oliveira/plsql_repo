CREATE OR REPLACE VIEW v_rehab_scheduled_session_my AS
SELECT rs.id_schedule,
       rp.id_patient,
       e.id_episode,
       re.id_episode_rehab,
       e.id_visit,
       rsn.id_resp_professional,
       rsn.id_resp_rehab_group,
       re.dt_creation,
       s.dt_begin_tstz,
       nvl(re.flg_status, 'A') AS flg_status,
       1442 shortcut,
       1 id_schedule_type,
       s.dt_schedule_tstz,
       rst.code_rehab_session_type,
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
       rsn.id_rehab_sch_need,
       rs.id_rehab_schedule,
       ei.id_software,
       ei.id_professional,
			 e.flg_status e_flg_status,
       s.id_schedule id_lock_uq_value,
       'REHAB_GRID_SCHED' lock_func,
       'S' grid_workflow_icon,
       'A' grid_workflow_icon_status,
       'S' flg_type,
       pk_message.get_message(sys_context('ALERT_CONTEXT', 'l_lang'), profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),sys_context('ALERT_CONTEXT', 'l_prof_institution'),sys_context('ALERT_CONTEXT', 'l_prof_software')), 'REHAB_T147') desc_schedule_type
  FROM rehab_schedule rs
  JOIN schedule s
    ON s.id_schedule = rs.id_schedule
  JOIN rehab_sch_need rsn
    ON rsn.id_rehab_sch_need = rs.id_rehab_sch_need
  JOIN rehab_session_type rst
    ON rst.id_rehab_session_type = rsn.id_rehab_session_type
  /*JOIN rehab_presc rpres
    ON rpres.id_rehab_sch_need = rsn.id_rehab_sch_need*/
  JOIN rehab_plan rp
    ON rp.id_episode_origin = rsn.id_episode_origin
  JOIN episode e
    ON e.id_episode = rsn.id_episode_origin 
  JOIN rehab_environment r
    ON r.id_epis_type = e.id_epis_type
   AND r.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
   AND r.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                    FROM rehab_environment_prof rep
                                   WHERE rep.id_professional = sys_context('ALERT_CONTEXT', 'l_prof_id'))
  JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = ei.id_bed
  LEFT JOIN room ro
    ON (ro.id_room = s.id_room OR ro.id_room = bd.id_room)
  LEFT JOIN department dpt
    ON dpt.id_department = ro.id_department
  LEFT JOIN rehab_epis_encounter re
    ON (re.id_episode_origin = e.id_episode AND re.dt_creation BETWEEN sys_context('ALERT_CONTEXT', 'l_dt_begin') AND sys_context('ALERT_CONTEXT', 'l_dt_end') AND
       re.id_rehab_sch_need = rsn.id_rehab_sch_need)
 WHERE s.dt_begin_tstz BETWEEN sys_context('ALERT_CONTEXT', 'l_dt_begin') AND sys_context('ALERT_CONTEXT', 'l_dt_end')
   AND rs.flg_status = 'A'
   AND s.id_instit_requested = sys_context('ALERT_CONTEXT', 'l_prof_institution')
   AND s.flg_status != 'T'
   AND s.flg_status != 'V'
   /*AND rpres.flg_status NOT IN ('C', 'D')*/
      --epis_origin activo
   AND ((e.flg_status = 'A' AND
       sys_context('ALERT_CONTEXT', 'l_scfg_rehab_needs_sch') = 'N') OR
       (sys_context('ALERT_CONTEXT', 'l_scfg_rehab_needs_sch') = 'Y') AND
       s.id_schedule IS NOT NULL)
	 AND ((rsn.id_resp_professional IS NOT NULL AND rsn.id_resp_professional = sys_context('ALERT_CONTEXT', 'l_prof_id')) OR
                               -- ou o meu grupo
                               (rsn.id_resp_rehab_group IS NOT NULL AND
                               rsn.id_resp_rehab_group IN (SELECT id_rehab_group
          FROM rehab_group_prof rgp
         WHERE rgp.id_professional = sys_context('ALERT_CONTEXT', 'l_prof_id'))
                               ));
