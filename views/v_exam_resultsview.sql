CREATE OR REPLACE VIEW v_exam_resultsview AS
SELECT eea.id_exam_req,
       eea.id_exam_req_det,
       eea.id_exam_result,
       eea.id_exam,
       eea.flg_type,
       eea.id_exam_cat,
       eea.flg_status_det,
       eea.flg_referral,
       eea.id_prof_req,
       eea.start_time,
       er.notes RESULT,
       er.id_result_status,
       er.id_abnormality,
       er.flg_relevant,
       ema.id_doc_external,
       er.id_external_doc,
       eea.id_patient,
       eea.id_episode,
       eea.id_visit,
       row_number() over(ORDER BY start_time) exam_number
  FROM exams_ea eea,
       exam_result er,
       (SELECT id_exam_result, id_doc_external
          FROM (SELECT ema.id_exam_result,
                       ema.id_doc_external,
                       row_number() over(PARTITION BY ema.id_exam_result ORDER BY ema.dt_last_update_tstz DESC NULLS FIRST) rn
                  FROM exam_media_archive ema, doc_external de
                 WHERE ema.flg_type = 'R'
                   AND ema.id_doc_external = de.id_doc_external
                   AND de.flg_status = 'A')
         WHERE rn = 1) ema
 WHERE eea.id_patient = sys_context('ALERT_CONTEXT', 'i_patient')
   AND eea.id_exam_result = er.id_exam_result
   AND er.id_exam_result = ema.id_exam_result(+)
   AND eea.id_exam_cat IN (SELECT num_1
                             FROM tbl_temp tt
                            WHERE tt.vc_1 = 'ID_EXAM_CAT');
