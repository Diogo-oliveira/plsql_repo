CREATE OR REPLACE VIEW V_ALL_PAT_AMB_GRID_ANCILIARY AS
SELECT e.id_episode,
       e.id_visit,
       e.id_patient,
       pat.gender,
       pat.dt_birth,
       pat.dt_deceased,
       pat.age,
       --
       ei.id_schedule,
       sp.dt_target_tstz,
       sp.flg_sched,
       ei.id_dep_clin_serv,
       ei.sch_prof_outp_id_prof,
       e.id_institution,
       e.flg_ehr,
       pdcs.id_professional,
       --
       gt.clin_rec_transp,
       gt.hemo_req,
       gt.supplies,
       gt.drug_transp,
       gt.movement,
       gt.harvest
  FROM episode e
  JOIN epis_info ei
    ON ei.id_episode = e.id_episode
  JOIN patient pat
    ON e.id_patient = pat.id_patient
  JOIN schedule_outp sp
    ON sp.id_schedule = ei.id_schedule
  JOIN sch_group sg
    ON sg.id_schedule = sp.id_schedule
   AND sg.id_patient = pat.id_patient
  JOIN clinical_service cs
    ON cs.id_clinical_service = e.id_clinical_service
  JOIN prof_dep_clin_serv pdcs
    ON (pdcs.id_dep_clin_serv = ei.id_dep_clin_serv AND pdcs.flg_status = 'S')
  JOIN grid_task gt
    ON gt.id_episode = e.id_episode
 WHERE sp.id_software = sys_context('ALERT_CONTEXT', 'i_software')
   AND e.flg_status != 'C'
   AND ei.flg_sch_status != 'C'
   AND e.flg_status <> 'I';
