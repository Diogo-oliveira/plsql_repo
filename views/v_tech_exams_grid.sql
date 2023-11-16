CREATE OR REPLACE VIEW V_TECH_EXAMS_GRID AS
            SELECT gti.acuity,
                   gti.rank_acuity,
                   gti.triage_color_text,
									 gti.id_episode,
									 gti.id_triage_color,
                   gti.id_epis_type,
									 gti.id_software,
								   gti.id_institution,
                   gti.dt_first_obs_tstz,
                   gti.id_patient,
                   gti.id_exam, 
                   gti.request,
									 gti.id_room,
                   gti.transport,
                   gti.execute,
                   gti.complete,
                   gti.id_exam_req_det,
                   gti.flg_status_req_det,
									 coalesce(gti.dt_pend_req_tstz, gti.dt_begin_tstz, gti.dt_req_tstz) dt_init
              FROM grid_task_img gti
             WHERE ((gti.flg_time_req = 'E' AND
                   gti.flg_status_epis NOT IN ('I', 'C')) OR
                   gti.flg_time_req = 'B' AND gti.dt_begin_tstz BETWEEN sys_context('ALERT_CONTEXT', 'i_dt_begin') AND
                   sys_context('ALERT_CONTEXT', 'i_dt_end') AND
                   gti.flg_status_req_det NOT IN ('A', 'PA') OR
                   (gti.flg_time_req = 'N' AND gti.id_episode IS NOT NULL AND
                   gti.flg_status_req_det != 'D'))
									 AND (EXISTS
                    (SELECT 1
                       FROM institution i
                      WHERE i.id_parent = (SELECT i.id_parent
                                             FROM institution i
                                            WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                        AND i.id_institution = gti.id_institution) OR gti.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution') OR
                    (gti.id_institution != sys_context('ALERT_CONTEXT', 'i_prof_institution') AND EXISTS
                     (SELECT 1
                        FROM transfer_institution ti
                       WHERE ti.flg_status = 'F'
                         AND ti.id_episode = gti.id_episode
                         AND ti.id_institution_dest = sys_context('ALERT_CONTEXT', 'i_prof_institution'))))
               AND EXISTS
             (SELECT 1
                      FROM prof_room pr
                     WHERE id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                       AND pr.id_room = gti.id_room)
               AND ((instr(nvl((SELECT flg_first_result
                                 FROM exam_dep_clin_serv e
                                WHERE e.id_exam = gti.id_exam
                                  AND e.flg_type = 'P'
                                  AND e.id_software = gti.id_software
                                  AND e.id_institution = gti.id_institution),
                               '#'),
                           sys_context('ALERT_CONTEXT', 'i_prof_cat_type')) != 0) OR sys_context('ALERT_CONTEXT', 'i_prof_cat_type') != 'T')

            UNION ALL
            SELECT gti.acuity,
                   gti.rank_acuity,
                   gti.triage_color_text,
                   gti.id_episode,
                   gti.id_triage_color,
                   gti.id_epis_type,
                   gti.id_software,
                   gti.id_institution,
                   gti.dt_first_obs_tstz,
                   gti.id_patient,
                   gti.id_exam, 
                   gti.request,
									 gti.id_room,
                   gti.transport,
                   gti.execute,
                   gti.complete,
                   gti.id_exam_req_det,
                   gti.flg_status_req_det,
									 coalesce(gti.dt_pend_req_tstz, gti.dt_begin_tstz, gti.dt_req_tstz) dt_init
              FROM grid_task_img gti
							   INNER JOIN episode epi on gti.id_episode = epi.id_prev_episode
             WHERE (gti.flg_time_req = 'E' AND
                   gti.flg_status_epis = 'I')
									 AND (EXISTS
                    (SELECT 1
                       FROM institution i
                      WHERE i.id_parent = (SELECT i.id_parent
                                             FROM institution i
                                            WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                        AND i.id_institution = gti.id_institution) OR gti.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution') OR
                    (gti.id_institution != sys_context('ALERT_CONTEXT', 'i_prof_institution') AND EXISTS
                     (SELECT 1
                        FROM transfer_institution ti
                       WHERE ti.flg_status = 'F'
                         AND ti.id_episode = gti.id_episode
                         AND ti.id_institution_dest = sys_context('ALERT_CONTEXT', 'i_prof_institution'))))
               AND EXISTS
             (SELECT 1
                      FROM prof_room pr
                     WHERE id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                       AND pr.id_room = gti.id_room)
               AND ((instr(nvl((SELECT flg_first_result
                                 FROM exam_dep_clin_serv e
                                WHERE e.id_exam = gti.id_exam
                                  AND e.flg_type = 'P'
                                  AND e.id_software = gti.id_software
                                  AND e.id_institution = gti.id_institution),
                               '#'),
                           sys_context('ALERT_CONTEXT', 'i_prof_cat_type')) != 0) OR sys_context('ALERT_CONTEXT', 'i_prof_cat_type') != 'T');