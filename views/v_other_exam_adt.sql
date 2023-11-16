CREATE OR REPLACE view v_other_exam_adt AS
    SELECT t.id_patient,
           t.pat_age,
           t.gender,
           t.num_clin_record,
           t.id_episode,
           listagg(t.id_exam_req, ';') id_req,
           listagg(t.id_exam_req_det, ';') id_req_det,
           t.id_institution,
           t.id_software,
           t.acuity,
           t.rank_acuity,
           t.id_epis_type,
           t.id_fast_track,
           t.id_triage_color,
           NULL dt_first_obs_tstz,
           t.dt_first_obs,
           'EO' flg_type,
           'TechnicianInContact' type_icon
      FROM (WITH aux AS (SELECT pdcs.id_dep_clin_serv
                           FROM prof_dep_clin_serv pdcs
                          WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                            AND pdcs.flg_status = 'S'
                            AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
               SELECT /*+ opt_estimate(table s rows=1) */
                gtoe.id_patient,
                to_char(gtoe.pat_age) pat_age,
                gtoe.gender,
                gtoe.num_clin_record,
                s.id_schedule,
                gtoe.id_episode,
                gtoe.id_exam,
                gtoe.id_exam_req,
                gtoe.id_exam_req_det,
                gtoe.id_institution,
                gtoe.id_software,
                gtoe.acuity,
                gtoe.rank_acuity,
                gtoe.id_epis_type,
                gtoe.id_fast_track,
                gtoe.id_triage_color,
                gtoe.dt_first_obs
                 FROM grid_task_oth_exm gtoe
                 JOIN (SELECT *
                         FROM TABLE(pk_schedule_exam.get_today_exam_appoints(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                             profissional(sys_context('ALERT_CONTEXT',
                                                                                                      'i_prof_id'),
                                                                                          sys_context('ALERT_CONTEXT',
                                                                                                      'i_prof_institution'),
                                                                                          sys_context('ALERT_CONTEXT',
                                                                                                      'i_prof_software')),
                                                                             current_timestamp))) s
                   ON gtoe.id_exam_req = s.id_exam_req
                WHERE gtoe.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                  AND (gtoe.flg_time IN ('D', 'B') OR
                      (gtoe.flg_time = 'E' AND (gtoe.id_episode IS NULL OR gtoe.id_epis_type = 21)))
                  AND EXISTS (SELECT 1
                         FROM prof_dep_clin_serv pdcs
                        WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                          AND pdcs.flg_status = 'S'
                          AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                          AND pdcs.id_dep_clin_serv IN
                              (SELECT ecd.id_dep_clin_serv
                                 FROM exam_cat_dcs ecd
                                WHERE ecd.id_exam_cat = gtoe.id_exam_cat))
                  AND sys_context('ALERT_CONTEXT', 'i_prof_software') IN (1, 15, 12, 39)
               UNION ALL
               SELECT gtoe.id_patient,
                      to_char(gtoe.pat_age) pat_age,
                      gtoe.gender,
                      gtoe.num_clin_record,
                      gtoe.id_schedule,
                      gtoe.id_episode,
                      gtoe.id_exam,
                      gtoe.id_exam_req,
                      gtoe.id_exam_req_det,
                      gtoe.id_institution,
                      gtoe.id_software,
                      gtoe.acuity,
                      gtoe.rank_acuity,
                      gtoe.id_epis_type,
                      gtoe.id_fast_track,
                      gtoe.id_triage_color,
                      gtoe.dt_first_obs
                 FROM grid_task_oth_exm gtoe
                 JOIN exams_ea eea
                   ON gtoe.id_exam_req_det = eea.id_exam_req_det
                WHERE (EXISTS (SELECT 1
                                 FROM institution i
                                WHERE i.id_parent =
                                      (SELECT i.id_parent
                                         FROM institution i
                                        WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                                  AND i.id_institution = gtoe.id_institution) OR
                       gtoe.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                  AND ((gtoe.flg_time = 'B' AND gtoe.dt_begin_tstz BETWEEN trunc(current_timestamp) AND
                      trunc(current_timestamp + 1) AND gtoe.flg_status_req_det NOT IN ('A', 'PA')) OR
                      (gtoe.flg_time = 'E' AND
                      pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                      sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                      sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                         gtoe.dt_begin_tstz) <= trunc(current_timestamp + 1) AND
                      gtoe.flg_status_epis NOT IN ('I', 'C')) OR
                      (gtoe.flg_time = 'N' AND gtoe.id_episode IS NOT NULL AND gtoe.flg_status_req_det != 'D'))
                  AND gtoe.flg_status_req_det NOT IN ('X', 'W', 'C')
                  AND EXISTS
                (SELECT 1
                         FROM aux a
                        WHERE a.id_dep_clin_serv IN (SELECT ecd.id_dep_clin_serv
                                                       FROM exam_cat_dcs ecd
                                                      WHERE ecd.id_exam_cat = gtoe.id_exam_cat))
                  AND instr(nvl((SELECT flg_first_result
                                  FROM exam_dep_clin_serv e
                                 WHERE e.id_exam = gtoe.id_exam
                                   AND e.flg_type = 'P'
                                   AND e.id_software = gtoe.id_software
                                   AND e.id_institution = gtoe.id_institution),
                                '#'),
                            'T') != 0
                  AND gtoe.id_announced_arrival IS NOT NULL) t
                GROUP BY t.id_patient,
                         t.pat_age,
                         t.gender,
                         t.num_clin_record,
                         t.id_episode,
                         t.id_institution,
                         t.id_software,
                         t.acuity,
                         t.rank_acuity,
                         t.id_epis_type,
                         t.id_fast_track,
                         t.id_triage_color,
                         t.dt_first_obs;