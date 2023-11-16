CREATE OR REPLACE VIEW v_lab_test_toschedule AS
SELECT DISTINCT gtl.id_analysis_req,
                gtl.id_patient,
                gtl.id_episode,
                gtl.acuity,
                gtl.rank_acuity,
                gtl.gender,
                gtl.pat_age,
                gtl.num_clin_record,
                gtl.id_dept,
                gtl.id_clinical_service,
                (SELECT COUNT(*)
                   FROM lab_tests_ea lte
                  WHERE lte.id_analysis_req = gtl.id_analysis_req) id_analysis_req_det,
                gtl.id_professional,
                gtl.id_institution,
                gtl.id_software,
                gtl.dt_req_tstz, 
                gtl.flg_status_ard
  FROM grid_task_lab gtl, exam_cat_dcs ecdcs
 WHERE (EXISTS (SELECT 1
                  FROM institution i
                 WHERE i.id_parent =
                       (SELECT i.id_parent
                          FROM institution i
                         WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                   AND i.id_institution = gtl.id_institution) OR
        gtl.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
   AND gtl.flg_time_harvest IN ('B', 'D')
   AND gtl.flg_status_ard IN ('PA', 'NR')
   AND gtl.id_exam_cat = ecdcs.id_exam_cat
   AND EXISTS (SELECT 1
          FROM prof_dep_clin_serv pdcs
         WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
           AND pdcs.flg_status = 'S'
           AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv);
