CREATE OR REPLACE VIEW v_rehab_grid_all_patients AS
SELECT flg_check_resp,
       alert_context('l_lang') i_lang,
       alert_context('l_prof_id') i_prof_id,
       alert_context('l_prof_institution') i_prof_institution,
       alert_context('l_prof_software') i_prof_software,
       s_id_group,
       flg_contact_type,
       coalesce(id_schedule, -1) id_schedule,
       id_patient,
       id_episode,
       id_episode_rehab,
       id_visit,
       id_epis_type,
       id_resp_professional,
       id_resp_rehab_group,
       dt_creation,
       dt_begin_tstz,
       flg_status,
       shortcut,
       id_schedule_type,
       dt_schedule_tstz,
       code_rehab_session_type,
       abbreviation,
       code_department,
       id_room,
       desc_room_abbreviation,
       code_abbreviation,
       code_room,
       desc_room,
       code_bed,
       desc_bed,
       id_rehab_epis_encounter,
       id_rehab_sch_need,
       id_rehab_schedule,
       id_software,
       id_professional,
       e_flg_status,
       id_lock_uq_value,
       lock_func,
       grid_workflow_icon,
       grid_workflow_icon_status,
       flg_type,
       desc_schedule_type,
       flg_ehr,
       dt_init
  FROM (SELECT 'Y' flg_check_resp,
               s_id_group,
               flg_contact_type,
               id_schedule,
               id_patient,
               id_episode,
               id_episode_rehab,
               id_visit,
               id_epis_type,
               id_resp_professional,
               id_resp_rehab_group,
               dt_creation,
               dt_begin_tstz,
               flg_status,
               shortcut,
               id_schedule_type,
               dt_schedule_tstz,
               code_rehab_session_type,
               abbreviation,
               code_department,
               id_room,
               desc_room_abbreviation,
               code_abbreviation,
               code_room,
               desc_room,
               code_bed,
               desc_bed,
               id_rehab_epis_encounter,
               id_rehab_sch_need,
               id_rehab_schedule,
               id_software,
               id_professional,
               e_flg_status,
               id_lock_uq_value,
               lock_func,
               grid_workflow_icon,
               grid_workflow_icon_status,
               flg_type,
               desc_schedule_type,
               NULL flg_ehr,
               NULL dt_init
          FROM v_rehab_scheduled_session
         WHERE (alert_context('l_is_treatment') = 'Y' OR alert_context('l_get_all') = 'Y')
        UNION ALL
        SELECT 'N' flg_check_resp,
               s_id_group,
               flg_contact_type,
               id_schedule,
               id_patient,
               id_episode,
               id_episode_rehab,
               id_visit,
               id_epis_type,
               id_resp_professional,
               id_resp_rehab_group,
               dt_creation,
               dt_begin_tstz,
               flg_status,
               shortcut,
               id_schedule_type,
               dt_schedule_tstz,
               code_rehab_session_type,
               abbreviation,
               code_department,
               id_room,
               desc_room_abbreviation,
               code_abbreviation,
               code_room,
               desc_room,
               code_bed,
               desc_bed,
               id_rehab_epis_encounter,
               id_rehab_sch_need,
               id_rehab_schedule,
               id_software,
               id_professional,
               e_flg_status,
               id_lock_uq_value,
               lock_func,
               grid_workflow_icon,
               grid_workflow_icon_status,
               flg_type,
               desc_schedule_type,
               NULL flg_ehr,
               NULL dt_init
          FROM v_rehab_unscheduled_treatments
         WHERE (alert_context('l_is_treatment') = 'Y' OR alert_context('l_get_all') = 'Y')
        UNION ALL
        SELECT 'Y' flg_check_resp,
               s_id_group,
               flg_contact_type,
               id_schedule,
               id_patient,
               id_episode,
               id_episode_rehab,
               id_visit,
               id_epis_type,
               id_resp_professional,
               id_resp_rehab_group,
               dt_creation,
               dt_begin_tstz,
               flg_status,
               shortcut,
               id_schedule_type,
               dt_schedule_tstz,
               code_rehab_session_type,
               abbreviation,
               code_department,
               id_room,
               desc_room_abbreviation,
               code_abbreviation,
               code_room,
               desc_room,
               code_bed,
               desc_bed,
               id_rehab_epis_encounter,
               id_rehab_sch_need,
               id_rehab_schedule,
               id_software,
               id_professional,
               e_flg_status,
               id_lock_uq_value,
               lock_func,
               grid_workflow_icon,
               grid_workflow_icon_status,
               flg_type,
               desc_schedule_type,
               flg_ehr,
               dt_init
          FROM v_rehab_appointment
         WHERE (alert_context('l_is_treatment') = 'N' OR alert_context('l_get_all') = 'Y')
        UNION ALL
        SELECT 'N' flg_check_resp,
               s_id_group,
               flg_contact_type,
               id_schedule,
               id_patient,
               id_episode,
               id_episode_rehab,
               id_visit,
               id_epis_type,
               id_resp_professional,
               id_resp_rehab_group,
               dt_creation,
               dt_begin_tstz,
               flg_status,
               shortcut,
               id_schedule_type,
               dt_schedule_tstz,
               code_rehab_session_type,
               abbreviation,
               code_department,
               id_room,
               desc_room_abbreviation,
               code_abbreviation,
               code_room,
               desc_room,
               code_bed,
               desc_bed,
               id_rehab_epis_encounter,
               id_rehab_sch_need,
               id_rehab_schedule,
               id_software,
               id_professional,
               e_flg_status,
               id_lock_uq_value,
               lock_func,
               grid_workflow_icon,
               grid_workflow_icon_status,
               flg_type,
               desc_schedule_type,
               NULL flg_ehr,
               NULL dt_init
          FROM v_rehab_plan
         WHERE (alert_context('l_is_treatment') = 'Y' OR alert_context('l_get_all') = 'Y'));
