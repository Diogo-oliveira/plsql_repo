CREATE OR REPLACE VIEW v_pending_case_manager AS
SELECT e.id_episode,
       e.id_patient,
			 o.id_opinion,
			 o.id_prof_questions
FROM episode e, opinion o, epis_info ei
             WHERE e.id_episode = o.id_episode
               AND e.id_episode = ei.id_episode
               AND e.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
               AND o.id_opinion_type = sys_context('ALERT_CONTEXT', 'i_type_opinion')
               AND (o.id_prof_questioned = sys_context('ALERT_CONTEXT', 'i_prof_id') OR o.id_prof_questioned IS NULL)
               AND (o.flg_state = 'V' OR
                   (o.flg_state = 'R' AND
                   pk_opinion.check_approval_need(profissional(o.id_prof_questions, e.id_institution, ei.id_software),
                                                    sys_context('ALERT_CONTEXT', 'i_type_opinion')) = 'N'));
																										
																										
