CREATE OR REPLACE VIEW v_rehab_grid_my_patients AS
WITH rehab_all_patients AS
 (SELECT CASE
              WHEN rg.lock_func = 'REHAB_GRID_PLAN' THEN
               rg.id_lock_uq_value
              ELSE
               NULL
          END id_rehab_epis_plan,
         rg.*
    FROM v_rehab_grid_all_patients rg)
SELECT 'N/A' flx_follow_episode,
       rap.flg_check_resp,
       rap.i_lang,
       rap.i_prof_id,
       rap.i_prof_institution,
       rap.i_prof_software,
       rap.s_id_group,
       rap.flg_contact_type,
       rap.id_schedule,
       rap.id_patient,
       rap.id_episode,
       rap.id_episode_rehab,
       rap.id_visit,
       rap.id_epis_type,
       rap.id_resp_professional,
       rap.id_resp_rehab_group,
       rap.dt_creation,
       rap.dt_begin_tstz,
       rap.flg_status,
       rap.shortcut,
       rap.id_schedule_type,
       rap.dt_schedule_tstz,
       rap.code_rehab_session_type,
       rap.abbreviation,
       rap.code_department,
       rap.id_room,
       rap.desc_room_abbreviation,
       rap.code_abbreviation,
       rap.code_room,
       rap.desc_room,
       rap.code_bed,
       rap.desc_bed,
       rap.id_rehab_epis_encounter,
       rap.id_rehab_sch_need,
       rap.id_rehab_schedule,
       rap.id_software,
       rap.id_professional,
       rap.e_flg_status,
       rap.id_lock_uq_value,
       rap.lock_func,
       rap.grid_workflow_icon,
       rap.grid_workflow_icon_status,
       rap.flg_type,
       rap.desc_schedule_type,
       rap.flg_ehr,
       rap.dt_init
  FROM rehab_all_patients rap
 WHERE nvl(rap.code_rehab_session_type, 'REHAB') != 'REHAB_M050'
   AND (rap.id_resp_professional = rap.i_prof_id OR rap.id_professional = rap.i_prof_id OR
        (pk_prof_follow.get_follow_episode_by_me(profissional(rap.i_prof_id,
                                                              rap.i_prof_institution,
                                                              rap.i_prof_software),
                                                 nvl(rap.id_episode_rehab, rap.id_episode),
                                                 nvl(rap.id_schedule, -1)) = 'Y') OR
        (rap.i_prof_id IN (SELECT sr.id_professional
                             FROM sch_resource sr
                            WHERE sr.id_schedule = rap.id_schedule)) OR
        (rap.lock_func = 'REHAB_GRID_PRESC' AND rap.flg_type = 'W'))
UNION ALL
SELECT 'N/A' flx_follow_episode,
       rap.flg_check_resp,
       rap.i_lang,
       rap.i_prof_id,
       rap.i_prof_institution,
       rap.i_prof_software,
       rap.s_id_group,
       rap.flg_contact_type,
       rap.id_schedule,
       rap.id_patient,
       rap.id_episode,
       rap.id_episode_rehab,
       rap.id_visit,
       rap.id_epis_type,
       rap.id_resp_professional,
       rap.id_resp_rehab_group,
       rap.dt_creation,
       rap.dt_begin_tstz,
       rap.flg_status,
       rap.shortcut,
       rap.id_schedule_type,
       rap.dt_schedule_tstz,
       rap.code_rehab_session_type,
       rap.abbreviation,
       rap.code_department,
       rap.id_room,
       rap.desc_room_abbreviation,
       rap.code_abbreviation,
       rap.code_room,
       rap.desc_room,
       rap.code_bed,
       rap.desc_bed,
       rap.id_rehab_epis_encounter,
       rap.id_rehab_sch_need,
       rap.id_rehab_schedule,
       rap.id_software,
       rap.id_professional,
       rap.e_flg_status,
       rap.id_lock_uq_value,
       rap.lock_func,
       rap.grid_workflow_icon,
       rap.grid_workflow_icon_status,
       rap.flg_type,
       rap.desc_schedule_type,
       rap.flg_ehr,
       rap.dt_init
  FROM rehab_all_patients rap
  JOIN rehab_epis_plan_team rept
    ON (rept.id_rehab_epis_plan = rap.id_rehab_epis_plan AND rept.flg_status = 'Y')
  JOIN prof_cat pc
    ON (rept.id_prof_cat = pc.id_prof_cat AND pc.id_professional = rap.i_prof_id);
