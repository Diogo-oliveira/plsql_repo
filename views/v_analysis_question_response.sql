CREATE OR REPLACE VIEW v_analysis_question_response AS
SELECT aqr.id_analysis_question_response,
       aqr.id_episode,
       aqr.id_analysis_req_det,
       aqr.id_harvest,
       q.id_questionnaire,
       r.id_response,
       aqr.notes,
       aqr.id_prof_last_update,
       aqr.dt_last_update_tstz,
       q.id_content                  id_content_questionnaire,
       r.id_content                  id_content_response,
	   ard.id_analysis,
	   nvl(ard.id_analysis,-1) as id_analysis_nvl,
	   ard.id_sample_type,
	   nvl(ard.id_sample_type,-1) as id_sample_type_nvl,
	   ard.id_analysis_group,
	   nvl(ard.id_analysis_group,-1) as id_analysis_group_nvl,
	   ar.id_institution,
	   nvl(aqr.id_response,-1) as id_response_nvl
  FROM analysis_question_response aqr
  INNER JOIN analysis_req_det ard
	ON (aqr.id_analysis_req_det=ard.id_analysis_req_det)
  INNER JOIN analysis_req ar
	ON (ard.id_analysis_req=ar.id_analysis_req)
  LEFT JOIN questionnaire q
    ON (q.id_questionnaire = aqr.id_questionnaire)
  LEFT JOIN response r
    ON (r.id_response = aqr.id_response);
