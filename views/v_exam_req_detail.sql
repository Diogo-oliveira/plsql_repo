CREATE OR REPLACE VIEW v_exam_req_detail AS
SELECT erd.id_exam_req,
       erd.id_exam_req_det,
       e.id_exam,
       e.code_exam,
       e.flg_type,
       er.id_episode,
       er.id_episode_origin,
       ep.id_visit,
       c.id_codification,
       c.code_codification,
       ec.standard_code,
       erd.flg_laterality,
       erd.id_exam_codification,
       erd.prof_dep_clin_serv,
       erd.id_prof_performed,
       erd.start_time dt_start_performing_tstz,
       mrd.id_diagnosis clinical_indication,
       mrd.id_epis_diagnosis,
       pk_hand_off.get_epis_dcs(NULL, NULL, er.id_episode, NULL, erd.start_time) place_of_service,
       csh.id_prof_ordered_by id_prof_order,
       erd.id_prof_performed_reg,
       erdh.id_prof_cancel,
       erdh.id_cancel_reason,
       erdh.notes_cancel
  FROM exam_req_det erd
 INNER JOIN exam_req er
    ON er.id_exam_req = erd.id_exam_req
  LEFT JOIN co_sign_hist csh
    ON (erd.id_co_sign_order = csh.id_co_sign_hist)
 INNER JOIN episode ep
    ON nvl(er.id_episode, er.id_episode_origin) = ep.id_episode
 INNER JOIN exam e
    ON e.id_exam = erd.id_exam
  LEFT OUTER JOIN mcdt_req_diagnosis mrd
    ON mrd.id_exam_req_det = erd.id_exam_req_det
  LEFT OUTER JOIN exam_codification ec
    ON ec.id_exam_codification = erd.id_exam_codification
  LEFT OUTER JOIN codification c
    ON c.id_codification = ec.id_codification
  LEFT OUTER JOIN (SELECT id_exam_req_det, id_prof_cancel, id_cancel_reason, notes_cancel
                     FROM (SELECT row_number() over(PARTITION BY id_exam_req_det ORDER BY id_exam_req_det_hist DESC) rownumber,
                                  id_exam_req_det,
                                  erdh.id_prof_cancel,
                                  erdh.id_cancel_reason,
                                  erdh.notes_cancel
                             FROM exam_req_det_hist erdh)
                    WHERE rownumber = 1) erdh
    ON erd.id_exam_req_det = erdh.id_exam_req_det;
