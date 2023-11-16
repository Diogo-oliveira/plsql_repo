CREATE OR REPLACE VIEW V_REHAB_CDC_APPOINTMENT AS
SELECT s.id_schedule,
       e.id_patient,
       e.id_episode,
       re.id_episode_rehab,
       e.id_visit,
       NULL id_resp_professional,
       NULL id_resp_rehab_group,
       re.dt_creation,
       s.dt_begin_tstz,
       pk_rehab.get_rehab_app_status(sys_context('ALERT_CONTEXT', 'l_lang'),
                                     profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),
                                                  sys_context('ALERT_CONTEXT', 'l_prof_institution'),
                                                  sys_context('ALERT_CONTEXT', 'l_prof_software')),
                                     e.id_patient,
                                     re.flg_status) flg_status,
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
       pk_message.get_message(sys_context('ALERT_CONTEXT', 'l_lang'),
                              profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),
                                           sys_context('ALERT_CONTEXT', 'l_prof_institution'),
                                           sys_context('ALERT_CONTEXT', 'l_prof_software')),
                              'REHAB_T148') desc_schedule_type,
       s.reason_notes,
       sp.flg_state,
       e.flg_ehr,
       ei.id_dep_clin_serv,
       s.id_dcs_requested,
       sp.dt_target_tstz,
       sg.flg_contact_type
  FROM schedule_outp sp
  JOIN schedule s
    ON s.id_schedule = sp.id_schedule
  JOIN sch_group sg
    ON sg.id_schedule = s.id_schedule
  JOIN epis_info ei
    ON s.id_schedule = ei.id_schedule
  JOIN epis_type et
    ON sp.id_epis_type = et.id_epis_type
  JOIN episode e
    ON ei.id_episode = e.id_episode
  LEFT JOIN rehab_epis_encounter re
    ON re.id_episode_origin = e.id_episode
 WHERE s.flg_sch_type = sys_context('ALERT_CONTEXT', 'l_flg_sch_type_cr')
   AND s.flg_status != 'V' -- agendamentos temporários (SCH 3.0)
   AND s.flg_status != 'C'
   AND s.id_instit_requested = sys_context('ALERT_CONTEXT', 'l_prof_institution')
   AND sp.id_epis_type = sys_context('ALERT_CONTEXT', 'l_epis_type_rehab_ap')
   AND sp.dt_target_tstz BETWEEN CAST(sys_context('ALERT_CONTEXT', 'l_dt_begin') AS TIMESTAMP WITH LOCAL TIME ZONE) AND
       CAST(sys_context('ALERT_CONTEXT', 'l_dt_end') AS TIMESTAMP WITH LOCAL TIME ZONE)
   AND (sys_context('ALERT_CONTEXT', 'l_show_med_disch') = 'Y' OR
       (sys_context('ALERT_CONTEXT', 'l_show_med_disch') = 'N' AND
       pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != 'D'));
