CREATE OR REPLACE VIEW v_rehab_scheduled_session AS
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
SELECT /*+ index(s SCH_SEARCH06_IDX) */
DISTINCT NULL s_id_group,
         flg_contact_type,
         rs.id_schedule,
         rp.id_patient,
         e.id_episode,
         rt.id_episode_rehab,
         e.id_visit,
         e.id_epis_type,
         rsn.id_resp_professional,
         rsn.id_resp_rehab_group,
         rt.dt_creation,
         s.dt_begin_tstz,
         nvl(rt.flg_status, 'A') flg_status,
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
         rt.id_rehab_epis_encounter,
         rsn.id_rehab_sch_need,
         rs.id_rehab_schedule,
         ei.id_software,
         rt.id_professional,
         nvl(rt.flg_status_epis, e.flg_status) e_flg_status,
         s.id_schedule id_lock_uq_value,
         'REHAB_GRID_SCHED' lock_func,
         'S' grid_workflow_icon,
         'A' grid_workflow_icon_status,
         'S' flg_type,
         (SELECT pk_message.get_message(aux.sys_lang, aux.sys_lprof, 'REHAB_T147')
            FROM dual) desc_schedule_type
  FROM schedule s
  JOIN rehab_schedule rs
    ON s.id_schedule = rs.id_schedule
  JOIN rehab_sch_need rsn
    ON rsn.id_rehab_sch_need = rs.id_rehab_sch_need
  JOIN rehab_session_type rst
    ON rst.id_rehab_session_type = rsn.id_rehab_session_type
  JOIN sch_group sg
    ON s.id_schedule = sg.id_schedule
  JOIN rehab_presc rpres
    ON rpres.id_rehab_sch_need = rsn.id_rehab_sch_need
  JOIN rehab_area_interv rai
    ON rai.id_rehab_area_interv = rpres.id_rehab_area_interv
  JOIN rehab_area ra
    ON ra.id_rehab_area = rai.id_rehab_area
  JOIN rehab_area_inst raii
    ON raii.id_rehab_area = ra.id_rehab_area
   AND raii.id_institution = alert_context('l_prof_institution')
  JOIN aux
    ON aux.sys_prof_institution = raii.id_institution
  JOIN rehab_area_inst_prof raip
    ON raip.id_rehab_area_inst = raii.id_rehab_area_inst
   AND raip.id_professional = aux.sys_prof_id
  JOIN rehab_plan rp
    ON rp.id_episode_origin = rsn.id_episode_origin
  JOIN episode e
    ON e.id_episode = rsn.id_episode_origin
  JOIN rehab_environment r
    ON r.id_epis_type = e.id_epis_type
   AND r.id_institution IN (0, aux.sys_prof_institution)
   AND r.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                    FROM rehab_environment_prof rep
                                   WHERE rep.id_professional = aux.sys_prof_id)
  JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  LEFT JOIN bed bd
    ON bd.id_bed = ei.id_bed
  LEFT JOIN room ro
    ON (ro.id_room = s.id_room OR ro.id_room = bd.id_room)
  LEFT JOIN department dpt
    ON dpt.id_department = ro.id_department
  LEFT JOIN (SELECT re.id_rehab_epis_encounter,
                    re.id_episode_rehab,
                    CASE re.flg_status
                        WHEN 'A' THEN
                         NULL
                        ELSE
                         re.dt_creation
                    END dt_creation,
                    re.flg_status,
                    eir.id_professional,
                    ree.flg_status flg_status_epis,
                    re.id_rehab_sch_need,
                    re.id_episode_origin,
                    eir.id_schedule
               FROM rehab_epis_encounter re
               JOIN episode ree
                 ON re.id_episode_rehab = ree.id_episode
               JOIN epis_info eir
                 ON eir.id_episode = ree.id_episode
                AND eir.id_episode = re.id_episode_rehab) rt
    ON (rt.id_schedule = rs.id_schedule AND rt.id_episode_origin = e.id_episode AND
       rt.id_rehab_sch_need = rsn.id_rehab_sch_need)
 WHERE 0 = 0
   AND s.dt_begin_tstz BETWEEN aux.sys_dt_begin AND aux.sys_dt_end
   AND rs.flg_status = 'A'
   AND s.id_instit_requested = aux.sys_prof_institution
   AND s.flg_status NOT IN ('T', 'V')
   AND rpres.flg_status NOT IN ('C', 'D')
   AND ((e.flg_status != 'C' AND aux.sys_scfg_rehab_needs_sch = 'N') OR
       (aux.sys_scfg_rehab_needs_sch = 'Y') AND s.id_schedule IS NOT NULL);
