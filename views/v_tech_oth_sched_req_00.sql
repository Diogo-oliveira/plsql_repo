CREATE OR REPLACE VIEW V_TECH_OTH_SCHED_REQ_00 AS
SELECT 'E' sel_type,
       'OTHER_EXAMS' event_type,
       5 id_event_type,
       oth.id_patient,
       pt.age,
       oth.num_clin_record,
       oth.id_episode,
       oth.id_dept,
       oth.id_clinical_service,
       oth.id_professional,
       oth.id_exam_cat,
       oth.id_exam,
       oth.dt_schedule_tstz,
       er.notes,
       oth.dt_begin_tstz,
       oth.id_exam_req,
       oth.id_exam_req_det,
       oth.flg_status_req_det,
       oth.dt_req_tstz,
       er.id_prof_req,
       er.id_institution,
       er.id_schedule,
       oth.flg_req_origin_module,
       pt.gender,
       pt.name,
       NULL id_room,
       NULL comb_name,
       NULL id_combination_spec
  FROM grid_task_oth_exm oth
  JOIN exam_req er
    ON er.id_exam_req = oth.id_exam_req
  JOIN patient pt
    ON pt.id_patient = oth.id_patient
 WHERE oth.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND ((oth.flg_status_req_det = 'PA' AND oth.dt_begin_tstz IS NULL) OR oth.flg_status_req_det = 'NR')
   AND EXISTS
 (SELECT 1
          FROM prof_dep_clin_serv pdcs
         WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
           AND pdcs.flg_status = 'S'
           AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pdcs.id_dep_clin_serv IN
               (SELECT ecdcs.id_dep_clin_serv FROM exam_cat_dcs ecdcs WHERE ecdcs.id_exam_cat = oth.id_exam_cat));