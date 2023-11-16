CREATE OR REPLACE VIEW V_TECH_IMG_SCHED_REQ_00 AS
SELECT 'I' sel_type,
       'IMAGING_EXAMS' event_type,
       4 id_event_type,
       gti.id_patient,
       pt.age,
       gti.num_clin_record,
       gti.id_episode,
       gti.id_dept,
       gti.id_clinical_service,
       gti.id_professional,
       gti.id_exam_cat,
       gti.id_exam,
       gti.dt_schedule_tstz,
       er.notes,
       gti.dt_begin_tstz,
       gti.id_exam_req,
       gti.id_exam_req_det,
       gti.flg_status_req_det,
       gti.dt_req_tstz,
       er.id_prof_req,
       er.id_institution,
       er.id_schedule,
       gti.flg_req_origin_module,
       pt.gender,
       pt.name,
       gti.id_room,
       NULL comb_name,
       NULL id_combination_spec
  FROM grid_task_img gti
  JOIN exam_req er
    ON er.id_exam_req = gti.id_exam_req
  JOIN patient pt
    ON pt.id_patient = gti.id_patient
 WHERE gti.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND ((gti.flg_status_req_det = 'PA' AND gti.dt_begin_tstz IS NULL) OR gti.flg_status_req_det = 'NR')
   AND EXISTS
 (SELECT 1
          FROM prof_dep_clin_serv pdcs
         WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
           AND pdcs.flg_status = 'S'
           AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pdcs.id_dep_clin_serv IN (SELECT ecdcs.id_dep_clin_serv
                                           FROM exam_cat_dcs ecdcs
                                          WHERE ecdcs.id_exam_cat = gti.id_exam_cat));