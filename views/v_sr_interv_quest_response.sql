CREATE OR REPLACE VIEW v_sr_interv_quest_response AS
SELECT siqr.id_sr_interv_quest_response,
       siqr.id_episode,
       siqr.id_sr_epis_interv,
       siqr.flg_time,
       q.id_questionnaire,
       r.id_response,
       siqr.notes,
       siqr.id_prof_last_update,
       siqr.dt_last_update_tstz,
       q.id_content                     id_content_questionnaire,
       r.id_content                     id_content_response
  FROM sr_interv_quest_response siqr
  LEFT JOIN questionnaire q
    ON (q.id_questionnaire = siqr.id_questionnaire)
  LEFT JOIN response r
    ON (r.id_response = siqr.id_response);