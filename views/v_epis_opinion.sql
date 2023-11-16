CREATE OR REPLACE VIEW V_EPIS_OPINION AS
SELECT o.id_opinion,
       o.id_prof_questioned,
       o.id_prof_questions,
       o.id_clinical_service,
       o.id_speciality,
       o.dt_problem_tstz,
       o.id_episode,
       o.flg_state,
       o.desc_problem,
       o.status_str,
       o.status_icon,
       o.status_msg,
       o.status_flg,
       o.dt_cancel_tstz,
       o.notes_cancel,
       op.id_professional op_id_professional,
       NULL p_id_professional,
       NULL p_req_id_professional,
       o.flg_priority,
       NULL code_speciality,
       NULL code_clinical_service,
       alert_context('i_lang') l_lang,
       alert_context('i_prof_id') l_prof_id,
       alert_context('i_prof_institution') l_prof_institution,
       alert_context('i_prof_software') l_prof_software
  FROM opinion o
 INNER JOIN episode e
    ON o.id_episode = e.id_episode
  LEFT JOIN opinion_prof op
    ON o.id_opinion = op.id_opinion
   AND o.flg_state = op.flg_type
 WHERE e.id_visit = alert_context('l_visit')
   AND o.flg_type = alert_context('l_flg_type')
   AND o.flg_state = 'P'
   AND alert_context('l_flg_type') IN ('O', 'U')
UNION ALL
SELECT o.id_opinion,
       o.id_prof_questioned,
       o.id_prof_questions,
       o.id_clinical_service,
       o.id_speciality,
       o.dt_problem_tstz,
       o.id_episode,
       o.flg_state,
       o.desc_problem,
       o.status_str,
       o.status_icon,
       o.status_msg,
       o.status_flg,
       o.dt_cancel_tstz,
       o.notes_cancel,
       op.id_professional op_id_professional,
       NULL p_id_professional,
       NULL p_req_id_professional,
       o.flg_priority,
       NULL code_speciality,
       NULL code_clinical_service,
       alert_context('i_lang') l_lang,
       alert_context('i_prof_id') l_prof_id,
       alert_context('i_prof_institution') l_prof_institution,
       alert_context('i_prof_software') l_prof_software
  FROM opinion o
 INNER JOIN episode e
    ON o.id_episode = e.id_episode
  LEFT JOIN opinion_prof op
    ON o.id_opinion = op.id_opinion
 WHERE e.id_visit = alert_context('l_visit')
   AND o.flg_type = alert_context('l_flg_type')
   AND o.flg_state IN ('F', 'R', 'C', 'A')
   AND alert_context('l_flg_type') IN ('O', 'U')
UNION ALL
SELECT o.id_opinion,
       o.id_prof_questioned,
       o.id_prof_questions,
       o.id_clinical_service,
       o.id_speciality,
       o.dt_problem_tstz,
       o.id_episode,
       o.flg_state,
       o.desc_problem,
       NULL status_str,
       NULL status_icon,
       NULL status_msg,
       NULL status_flg,
       o.dt_cancel_tstz,
       o.notes_cancel,
       NULL op_id_professional,
       NULL p_id_professional,
       NULL p_req_id_professional,
       o.flg_priority,
       NULL code_speciality,
       NULL code_clinical_service,
       alert_context('i_lang') l_lang,
       alert_context('i_prof_id') l_prof_id,
       alert_context('i_prof_institution') l_prof_institution,
       alert_context('i_prof_software') l_prof_software
  FROM opinion o
  JOIN opinion_type ot
    ON o.id_opinion_type = ot.id_opinion_type
  JOIN opinion_type_category otc
    ON otc.id_opinion_type = ot.id_opinion_type
  JOIN category c
    ON otc.id_category = c.id_category
  JOIN episode e
    ON o.id_episode = e.id_episode
 WHERE c.flg_type = 'Q'
   AND o.id_patient = alert_context('l_patient')
   AND alert_context('l_flg_type') = 'Q'
UNION ALL
SELECT o.id_opinion,
       o.id_prof_questioned,
       o.id_prof_questions,
       o.id_clinical_service,
       o.id_speciality,
       o.dt_problem_tstz,
       o.id_episode,
       o.flg_state,
       o.desc_problem,
       o.status_str,
       o.status_icon,
       o.status_msg,
       o.status_flg,
       o.dt_cancel_tstz,
       o.notes_cancel,
       NULL op_id_professional,
       p.id_professional p_id_professional,
       p_req.id_professional p_req_id_professional,
       o.flg_priority,
       s.code_speciality,
       cs.code_clinical_service,
       alert_context('i_lang') l_lang,
       alert_context('i_prof_id') l_prof_id,
       alert_context('i_prof_institution') l_prof_institution,
       alert_context('i_prof_software') l_prof_software
  FROM opinion o
 INNER JOIN episode e
    ON o.id_episode = e.id_episode
 INNER JOIN professional p_req
    ON p_req.id_professional = o.id_prof_questions
  LEFT JOIN professional p
    ON o.id_prof_questioned = p.id_professional
  LEFT JOIN speciality s
    ON o.id_speciality = s.id_speciality
  LEFT JOIN clinical_service cs
    ON o.id_clinical_service = cs.id_clinical_service
 WHERE e.id_visit = alert_context('l_visit')
   AND o.id_opinion_type IS NULL
   AND alert_context('l_flg_type') = 'N'
   AND o.flg_state NOT IN ('PD');
