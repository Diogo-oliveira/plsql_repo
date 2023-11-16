create or replace view 
v_rehab_epis_encounter
as             
SELECT ree.id_rehab_epis_encounter,
       ree.id_episode_origin,
       ree.id_episode_rehab,
       ree.flg_status,
       ree.flg_rehab_workflow_type,
       ree.id_prof_creation,
       ree.dt_creation,
       ree.dt_last_update,
       ree.id_cancel_reason,
       ree.dt_cancel,
       ree.id_prof_cancel,
       ree.cancel_notes,
       ree.id_rehab_sch_need
  FROM rehab_epis_encounter ree;