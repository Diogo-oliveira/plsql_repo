CREATE OR REPLACE VIEW V_MY_PARAMEDICAL_REQUESTS AS
SELECT o.id_opinion,
       o.flg_auto_follow_up,
       e.id_episode,
       eo.id_patient,
       eo.id_epis_type,
       et.code_epis_type,
       p.gender,
       p.dt_birth,
       p.age,
       o.id_prof_questions id_professional,
       o.dt_last_update,
       --o.id_episode id_episode_origin,
       sys_context('ALERT_CONTEXT', 'l_prof_templ') id_episode_origin,
       eid.id_professional id_prof_answer,
       o.desc_problem,
       o.flg_state,
       dep.id_department,
       dep.code_department,
       dep.rank rank_department,
       r.id_room,
       r.code_room,
       r.rank rank_room,
       b.id_bed,
       b.code_bed,
       decode(b.flg_type, 'T', b.desc_bed) desc_temp_bed,
       b.rank rank_bed,
       decode(eo.id_epis_type, 2, 'Y', 'N') show_triage,
       ei.triage_acuity acuity,
       ei.triage_color_text color_text,
       ei.triage_rank_acuity rank_acuity,
       ei.id_triage_color,
       eo.id_fast_track,
       ei.dt_first_obs_tstz,
       o.flg_type,
       o.id_prof_questioned,
       o.dt_approved,
       b.desc_bed,
       r.desc_room desc_room_used,
       eo.id_episode id_episode_answer,
       op.id_professional id_prof_resp,
       sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
       sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
       sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
       sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software,
       (SELECT cr.num_clin_record
          FROM clin_record cr
         WHERE cr.id_patient = eo.id_patient
           AND cr.id_institution = eo.id_institution
           AND rownum < 2) num_clin_record,
       (lpad(pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'l_lang'), 'OPINION.FLG_STATE', o.flg_state), 6, '0') ||
       pk_date_utils.to_char_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'l_prof_id'),
                                                        sys_context('ALERT_CONTEXT', 'l_prof_institution'),
                                                        sys_context('ALERT_CONTEXT', 'l_prof_software')),
                                           o.dt_problem_tstz,
                                           'YYYYMMDDHH24MISS TZR')) status_string_rank,
				o.id_opinion_type
  FROM opinion o
  JOIN episode eo
    ON o.id_episode = eo.id_episode
   AND eo.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
   AND eo.flg_status NOT IN ('C')
  JOIN patient p
    ON p.id_patient = eo.id_patient
  JOIN epis_type et
    ON eo.id_epis_type = et.id_epis_type
  JOIN epis_info ei
    ON eo.id_episode = ei.id_episode
  LEFT JOIN opinion_prof op
    ON o.id_opinion = op.id_opinion
   AND op.flg_type IN ('E', 'X')
  LEFT JOIN episode e
    ON o.id_episode_answer = e.id_episode
  LEFT JOIN epis_info eid
    ON e.id_episode = eid.id_episode
  LEFT JOIN bed b
    ON ei.id_bed = b.id_bed
   AND b.flg_available = 'Y'
  LEFT JOIN room r
    ON r.id_room = b.id_room
   AND r.flg_available = 'Y'
  LEFT JOIN department dep
    ON dep.id_department = r.id_department
   AND dep.flg_available = 'Y'
  LEFT JOIN discharge d
    ON e.id_episode = d.id_episode
   AND d.flg_status = 'A'
 WHERE o.id_opinion_type IN
       (SELECT otc.id_opinion_type
          FROM opinion_type_category otc
         WHERE otc.flg_available = 'Y'
           AND ((otc.id_category = sys_context('ALERT_CONTEXT', 'l_category') AND otc.id_profile_template IS NULL) OR
               (otc.id_profile_template = sys_context('ALERT_CONTEXT', 'l_prof_templ'))))
   AND ((sys_context('ALERT_CONTEXT', 'l_prof_id') IN (op.id_professional, o.id_prof_questioned) OR EXISTS
        (SELECT 1
            FROM (SELECT decode(sys_context('ALERT_CONTEXT', 'l_prof_cat_type'),
                                'D',
                                nvl(ei_1.id_professional, sr.id_professional),
                                'N',
                                ei_1.id_first_nurse_resp,
                                nvl(ei_1.id_professional, sr.id_professional)) id_professional
                    FROM epis_info ei_1
                    JOIN episode e1
                      ON e1.id_episode = ei_1.id_episode
                    LEFT JOIN sch_resource sr
                      ON ei_1.id_schedule = sr.id_schedule
                   WHERE sys_context('ALERT_CONTEXT', 'l_hand_off_type') = 'N'
                     AND sys_context('ALERT_CONTEXT', 'l_prof_cat_type') IN ('D', 'N')
                     AND e1.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution')
                     AND ei_1.id_software = sys_context('ALERT_CONTEXT', 'l_prof_software')
                     AND (nvl(ei_1.id_professional, sr.id_professional) = sys_context('ALERT_CONTEXT', 'l_prof_id') OR
                          ei_1.id_first_nurse_resp = sys_context('ALERT_CONTEXT', 'l_prof_id'))
                  UNION
                  SELECT empr.id_professional
                    FROM epis_multi_prof_resp empr
                    JOIN epis_prof_resp epr
                      ON epr.id_epis_prof_resp = empr.id_epis_prof_resp
                    JOIN epis_info ei_2
                      ON ei_2.id_episode = epr.id_episode
                     AND ei_2.id_software = sys_context('ALERT_CONTEXT', 'l_prof_software')
                   WHERE sys_context('ALERT_CONTEXT', 'l_hand_off_type') = 'M'
                     AND empr.flg_status = 'A'
                     AND empr.flg_resp_type = 'E'
                     AND epr.flg_type = sys_context('ALERT_CONTEXT', 'l_prof_cat_type')
                     AND epr.flg_status = 'F')) OR EXISTS
        (SELECT 1
            FROM prof_follow_opinion pfo
           WHERE pfo.id_professional = sys_context('ALERT_CONTEXT', 'l_prof_id')
             AND pfo.id_opinion = o.id_opinion
             AND pfo.flg_active = 'Y')))
   AND (o.flg_state IN ('E', 'V') OR
       (o.flg_state = 'R' AND
       alert.pk_opinion.check_approval_need(profissional(o.id_prof_questions,
                                                           eo.id_institution,
                                                           decode(o.id_opinion_type,
                                                                  4,
                                                                  sys_context('ALERT_CONTEXT', 'l_prof_software'),
                                                                  decode(et.id_epis_type,
                                                                         50,
                                                                         312,
                                                                         99,
                                                                         312,
                                                                         ei.id_software))),
                                              o.id_opinion_type) = 'N') OR
       (o.flg_state = 'X' AND op.dt_opinion_prof_tstz > sys_context('ALERT_CONTEXT', 'l_today')) OR
       (o.flg_state = 'O' AND
       ((d.dt_med_tstz > sys_context('ALERT_CONTEXT', 'l_today') OR
       op.dt_opinion_prof_tstz > sys_context('ALERT_CONTEXT', 'l_today')) OR
       (4 IN (SELECT otc.id_opinion_type
                   FROM opinion_type_category otc
                  WHERE otc.id_category = sys_context('ALERT_CONTEXT', 'l_category')) AND d.dt_med_tstz IS NULL AND
       (SELECT dis.dt_med_tstz
              FROM discharge dis
             WHERE dis.id_episode = eo.id_episode
               AND dis.flg_status = 'A') > sys_context('ALERT_CONTEXT', 'l_today')))));
