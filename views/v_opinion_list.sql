CREATE OR REPLACE VIEW V_OPINION_LIST AS
SELECT o.id_opinion,
       o.flg_state,
       o.id_prof_questions,
       o.dt_last_update,
       o.id_opinion_type,
       o.id_episode,
       ot.code_opinion_type,
       cs.code_clinical_service,
       o.id_prof_questioned,
       o.desc_problem,
       et.code_epis_type,
       o.dt_problem_tstz,
       o.id_episode_answer,
       alert_context('i_lang') sys_lang,
       alert_context('i_id_prof') sys_id_prof,
       alert_context('i_id_institution') sys_institution,
       alert_context('i_id_software') sys_software,
       CASE
            WHEN o.flg_state IN ('R', 'V', 'E') THEN
             'A'
            WHEN o.flg_state IN ('N', 'O') THEN
             'I'
            WHEN o.flg_state IN ('C') THEN
             'C'
            WHEN o.flg_state IN ('X') THEN
             'R'
            ELSE
             'X'
        END flg_cst_filter
  FROM opinion o
  JOIN opinion_type ot
    ON ot.id_opinion_type = o.id_opinion_type
  JOIN episode e
    ON e.id_episode = o.id_episode
  JOIN epis_type et
    ON et.id_epis_type = e.id_epis_type
  LEFT OUTER JOIN clinical_service cs
    ON cs.id_clinical_service = o.id_clinical_service
 WHERE o.id_patient = alert_context('i_patient')
   AND e.id_institution = alert_context('i_id_institution')
   AND ((ot.id_opinion_type IN (10, 6, 11, 12, 13) AND alert_context('i_id_software') IN (312, 313)) OR
       (alert_context('i_id_software') NOT IN (312, 313)));
