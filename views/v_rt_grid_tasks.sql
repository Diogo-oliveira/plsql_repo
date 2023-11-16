CREATE OR REPLACE VIEW v_rt_grid_tasks AS
WITH prof_cntx AS
 (SELECT flg_type, id_context
    FROM profile_context pc
   WHERE pc.id_institution IN (sys_context('ALERT_CONTEXT', 'l_prof_institution'), 0)
     AND pc.id_profile_template = sys_context('ALERT_CONTEXT', 'l_current_profile')
     AND pc.flg_available = 'Y')
SELECT epis.triage_acuity,
       epis.triage_color_text,
       epis.id_software,
       epis.id_epis_type,
       epis.triage_flg_letter,
       epis.id_episode,
       epis.id_patient,
       epis.id_schedule,
       epis.id_clinical_service,
       epis.dt_begin_tstz_e,
       epis.dt_first_obs_tstz,
       epis.id_visit,
       epis.has_transfer,
       epis.id_fast_track,
       epis.id_triage_color,
       epis.id_room,
       epis.id_professional,
       epis.id_first_nurse_resp,
       epis.triage_rank_acuity,
       r.desc_room_abbreviation,
       r.desc_room,
       sys_context('ALERT_CONTEXT', 'l_lang') i_lang,
       sys_context('ALERT_CONTEXT', 'l_prof_id') i_prof_id,
       sys_context('ALERT_CONTEXT', 'l_prof_institution') i_prof_institution,
       sys_context('ALERT_CONTEXT', 'l_prof_software') i_prof_software
  FROM v_episode_act epis
  JOIN room r
    ON r.id_room = epis.id_room
 WHERE (EXISTS
        (SELECT 0
           FROM prof_cntx pc
          WHERE (EXISTS (SELECT 0
                           FROM lab_tests_ea t
                          WHERE t.flg_status_req NOT IN ('PD', 'DF', 'X', 'L', 'C', 'LP', 'F', 'A')
                            AND pc.id_context = t.id_analysis
                            AND t.id_visit = epis.id_visit
                            AND pc.flg_type = 'A') --
                 OR EXISTS (SELECT 0
                              FROM exams_ea t
                             WHERE t.flg_status_req NOT IN ('PD', 'DF', 'C', 'F', 'LP', 'L')
                               AND pc.id_context = t.id_exam
                               AND epis.id_episode IN (t.id_episode, t.id_prev_episode)
                               AND pc.flg_type = 'E') --
                 OR EXISTS (SELECT 0
                              FROM procedures_ea pea, interv_prescription ip
                             WHERE pea.id_interv_prescription = ip.id_interv_prescription
                               AND ip.flg_status IN ('R', 'D', 'E', 'P')
                               AND pea.flg_status_plan IN ('R', 'D')
                               AND pc.id_context = pea.id_intervention
                               AND epis.id_episode IN (ip.id_episode, ip.id_prev_episode)
                               AND pc.flg_type = 'I') --
                 OR EXISTS (SELECT 0
                              FROM monitorizations_ea mea
                             WHERE mea.flg_status IN ('A', 'D')
                               AND pc.id_context = mea.id_vital_sign
                               AND epis.id_episode IN (mea.id_episode, mea.id_prev_episode)
                               AND pc.flg_type = 'M')) --
         ) OR epis.id_visit IN
        (SELECT e.id_visit
                 FROM prof_cntx pc
                 JOIN v_presc_med_comp pmc
                   ON rpad(pmc.id_product_supplier, 10) || pmc.id_product = pc.id_context
                 JOIN presc p
                   ON p.id_presc = pmc.id_presc
                 JOIN episode e
                   ON e.id_episode = p.id_last_episode
                WHERE pc.flg_type = 'D'
                  AND p.id_workflow IN (13, 20)
                  AND p.id_status IN (51, 57, 58, 63, 64, 65, 66, 67, 69, 70, 71, 92, 93, 95, 98, 160, 162)) --
       )
   AND epis.id_institution = sys_context('ALERT_CONTEXT', 'l_prof_institution');
