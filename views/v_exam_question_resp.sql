CREATE OR REPLACE VIEW v_exam_question_resp AS
SELECT qr.id_exam_question_response,
       qr.id_episode,
       qr.id_exam_req_det,
       qr.flg_time,
       q.id_questionnaire,
       r.id_response,
       qr.notes,
       qr.id_prof_last_update,
       qr.dt_last_update_tstz,
       q.id_content              id_content_questionnaire,
       r.id_content              id_content_response,
	   erd.id_exam,
	   nvl(erd.id_exam,-1) as id_exam_nvl,
	   erd.id_exam_group,
	   nvl(erd.id_exam_group,-1) as id_exam_group_nvl,
	   er.id_institution,
	   nvl(qr.id_response,-1) as id_response_nvl
  FROM exam_question_response qr
  INNER JOIN exam_req_det erd
	ON (qr.id_exam_req_det=erd.id_exam_req_det)
  INNER JOIN exam_req er
	ON (erd.id_exam_req=er.id_exam_req)
  LEFT JOIN questionnaire q
    ON (q.id_questionnaire = qr.id_questionnaire)
  LEFT JOIN response r
    ON (r.id_response = qr.id_response);
  