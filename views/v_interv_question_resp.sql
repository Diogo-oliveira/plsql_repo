CREATE OR REPLACE VIEW v_interv_question_resp AS
SELECT iqr.id_interv_question_response,
       iqr.id_episode,
       iqr.id_interv_presc_det,
       iqr.flg_time,
       q.id_questionnaire,
       r.id_response,
       iqr.notes,
       iqr.id_prof_last_update,
       iqr.dt_last_update_tstz,
       q.id_content              id_content_questionnaire,
       r.id_content              id_content_response,
	   ipd.id_intervention,
	   ip.id_institution,
	   nvl(iqr.id_response,-1) as id_response_nvl
  FROM interv_question_response iqr
  INNER JOIN interv_presc_det ipd
	ON (iqr.id_interv_presc_det=ipd.id_interv_presc_det)
  INNER JOIN interv_prescription ip
	ON (ipd.id_interv_prescription=ip.id_interv_prescription)  
  LEFT JOIN questionnaire q
    ON (q.id_questionnaire = iqr.id_questionnaire)
  LEFT JOIN response r
    ON (r.id_response = iqr.id_response);
  
