CREATE OR REPLACE VIEW v_opinion_answer AS
SELECT
--Opinion information
 o.id_opinion,
 o.id_patient,
 o.id_episode,
 e.id_visit,
 o.flg_state,
 --Description
 op.desc_reply,
 --Answering date
 op.dt_opinion_prof_tstz,
 --Request specialty
 pk_prof_utils.get_reg_prof_id_dcs(o.id_prof_questions,
                                   (SELECT MAX(op.dt_opinion_prof_tstz)
                                      FROM opinion_prof op
                                     WHERE op.id_opinion = o.id_opinion
                                       AND op.flg_type = 'R'),
                                   o.id_episode) req_prof_dcs,
 --Requested by
 o.id_prof_questions,
 --Answer specialty
 pk_prof_utils.get_reg_prof_id_dcs(op.id_professional, op.dt_opinion_prof_tstz, o.id_episode) answer_prof_dcs,
 --Answered by
 op.id_professional id_professional_answer,
 --Place of Service
 pk_hand_off.get_epis_dcs(NULL, NULL, o.id_episode, NULL, op.dt_opinion_prof_tstz) answer_epis_dcs
  FROM opinion o
  JOIN episode e
    ON e.id_episode = o.id_episode
  JOIN opinion_prof op
    ON o.id_opinion = op.id_opinion
 WHERE op.flg_type = 'P'; -- resposta ao parecer