CREATE OR REPLACE view v_imaging_exam_adt AS
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
           NULL id_fast_track,
           t.id_triage_color,
           t.dt_first_obs_tstz,
           NULL dt_first_obs,
           'EI' flg_type,
           'ImageExameIcon' type_icon
      FROM (SELECT /*+ opt_estimate(table s rows=1) */
             gti.id_patient,
             to_char(gti.pat_age) pat_age,
             gti.pat_gender gender,
             gti.num_clin_record,
             s.id_schedule,
             gti.id_episode,
             gti.id_exam,
             gti.id_exam_req,
             gti.id_exam_req_det,
             gti.id_institution,
             gti.id_software,
             gti.acuity,
             gti.rank_acuity,
             gti.id_epis_type,
             gti.id_triage_color,
             gti.dt_first_obs_tstz
              FROM grid_task_img gti
              JOIN (SELECT *
                     FROM TABLE(pk_schedule_exam.get_today_exam_appoints(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                         profissional(sys_context('ALERT_CONTEXT',
                                                                                                  'i_prof_id'),
                                                                                      sys_context('ALERT_CONTEXT',
                                                                                                  'i_prof_institution'),
                                                                                      sys_context('ALERT_CONTEXT',
                                                                                                  'i_prof_software')),
                                                                         current_timestamp))) s
                ON gti.id_exam_req = s.id_exam_req
             WHERE gti.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
               AND (gti.flg_time_req IN ('D', 'B') OR
                   (gti.flg_time_req = 'E' AND (gti.id_episode IS NULL OR gti.id_epis_type = 13)))
               AND EXISTS
             (SELECT 1
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                       AND pdcs.flg_status = 'S'
                       AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                       AND pdcs.id_dep_clin_serv IN (SELECT ecd.id_dep_clin_serv
                                                       FROM exam_cat_dcs ecd
                                                      WHERE ecd.id_exam_cat = gti.id_exam_cat))
               AND sys_context('ALERT_CONTEXT', 'i_prof_software') IN (1, 15, 12, 39)
            UNION ALL
            SELECT gti.id_patient,
                   to_char(gti.pat_age) pat_age,
                   gti.pat_gender gender,
                   gti.num_clin_record,
                   NULL id_schedule,
                   gti.id_episode,
                   gti.id_exam,
                   gti.id_exam_req,
                   gti.id_exam_req_det,
                   gti.id_institution,
                   gti.id_software,
                   gti.acuity,
                   gti.rank_acuity,
                   gti.id_epis_type,
                   gti.id_triage_color,
                   gti.dt_first_obs_tstz
              FROM grid_task_img gti
             WHERE ((gti.flg_time_req = 'E' AND gti.flg_status_epis NOT IN ('I', 'C')) OR
                   gti.flg_time_req = 'B' AND gti.dt_begin_tstz BETWEEN trunc(current_timestamp) AND
                   trunc(current_timestamp + 1) AND gti.flg_status_req_det NOT IN ('A', 'PA') OR
                   (gti.flg_time_req = 'N' AND gti.id_episode IS NOT NULL AND gti.flg_status_req_det != 'D'))
               AND (EXISTS (SELECT 1
                              FROM institution i
                             WHERE i.id_parent =
                                   (SELECT i.id_parent
                                      FROM institution i
                                     WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                               AND i.id_institution = gti.id_institution) OR
                    gti.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution') OR
                    (gti.id_institution != sys_context('ALERT_CONTEXT', 'i_prof_institution') AND EXISTS
                     (SELECT 1
                               FROM transfer_institution ti
                              WHERE ti.flg_status = 'F'
                                AND ti.id_episode = gti.id_episode
                                AND ti.id_institution_dest = sys_context('ALERT_CONTEXT', 'i_prof_institution'))))
               AND EXISTS (SELECT 1
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
                           sys_context('ALERT_CONTEXT', 'i_prof_cat_type')) != 0) OR
                   sys_context('ALERT_CONTEXT', 'i_prof_cat_type') != 'T')
            UNION ALL
            SELECT gti.id_patient,
                   to_char(gti.pat_age) pat_age,
                   gti.pat_gender gender,
                   gti.num_clin_record,
                   NULL id_schedule,
                   gti.id_episode,
                   gti.id_exam,
                   gti.id_exam_req,
                   gti.id_exam_req_det,
                   gti.id_institution,
                   gti.id_software,
                   gti.acuity,
                   gti.rank_acuity,
                   gti.id_epis_type,
                   gti.id_triage_color,
                   gti.dt_first_obs_tstz
              FROM grid_task_img gti
             INNER JOIN episode epi
                ON gti.id_episode = epi.id_prev_episode
             WHERE (gti.flg_time_req = 'E' AND gti.flg_status_epis = 'I')
               AND (EXISTS (SELECT 1
                              FROM institution i
                             WHERE i.id_parent =
                                   (SELECT i.id_parent
                                      FROM institution i
                                     WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                               AND i.id_institution = gti.id_institution) OR
                    gti.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution') OR
                    (gti.id_institution != sys_context('ALERT_CONTEXT', 'i_prof_institution') AND EXISTS
                     (SELECT 1
                               FROM transfer_institution ti
                              WHERE ti.flg_status = 'F'
                                AND ti.id_episode = gti.id_episode
                                AND ti.id_institution_dest = sys_context('ALERT_CONTEXT', 'i_prof_institution'))))
               AND EXISTS (SELECT 1
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
                           sys_context('ALERT_CONTEXT', 'i_prof_cat_type')) != 0) OR
                   sys_context('ALERT_CONTEXT', 'i_prof_cat_type') != 'T')) t
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
              t.id_triage_color,
              t.dt_first_obs_tstz;