CREATE OR REPLACE VIEW v_case_management_all AS
SELECT sql_rn,
       id_episode,
       id_patient,
       id_epis_encounter,
       flg_type,
       flg_status,
       flg_encounter_status,
       dt_epis_encounter,
       id_prof_questions,
       id_opinion,
       id_episode o_id_episode,
       substr(concatenate(pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                         'REASON_ENCOUNTER.CODE_REASON.' || id_reason) || '; '),
              1,
              length(concatenate(pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                'REASON_ENCOUNTER.CODE_REASON.' || id_reason) || '; ')) - 2) encounter_reason,
       rank_image
  FROM (SELECT 3 sql_rn,
                e.id_episode,
                e.id_patient,
                ec.id_epis_encounter,
                ec.flg_type,
                ec.flg_status,
                ec.flg_encounter_status,
                ec.dt_epis_encounter,
                o.id_prof_questions,
                o.id_opinion,
                o.id_episode o_id_episode,
                ecr.id_reason,
                decode(ec.flg_encounter_status, 'N', NULL, ecr.id_reason) encounter_reason,
                rank_image
           FROM episode e,
                -- ENCOUNTERS OF THE DAY
                (SELECT ee.id_epis_encounter,
                         ee.id_episode,
                         ee.dt_create,
                         ee.dt_epis_encounter,
                         ee.flg_status,
                         ee.flg_type,
                         'C' flg_encounter_status,
                         ee.id_professional,
                         decode(ee.flg_status, 'R', 1, 'A', 2, 'C', 7, 'I', 3) rank_image
                    FROM epis_encounter ee
                   WHERE ee.flg_status IN ('R', 'A', 'C', 'I')
                     AND ee.dt_epis_encounter BETWEEN sys_context('ALERT_CONTEXT', 'l_dt_begin') AND
                         sys_context('ALERT_CONTEXT', 'l_dt_end')
                  UNION
                  -- LATE ENCOUNTERS
                  SELECT ee.id_epis_encounter,
                         ee.id_episode,
                         ee.dt_create,
                         ee.dt_epis_encounter,
                         ee.flg_status,
                         ee.flg_type,
                         'L' flg_encounter_status,
                         ee.id_professional,
                         decode(ee.flg_status, 'R', 5, 'A', 4) rank_image
                    FROM epis_encounter ee
                   WHERE ee.flg_status IN ('R', 'A')
                     AND pk_date_utils.compare_dates_tsz(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                      sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                      sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                         pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT',
                                                                                                                   'l_prof_id'),
                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                   'l_prof_institution'),
                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                   'l_prof_software')),
                                                                                          ee.dt_epis_encounter),
                                                         pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT',
                                                                                                                   'l_prof_id'),
                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                   'l_prof_institution'),
                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                   'l_prof_software')),
                                                                                          sys_context('ALERT_CONTEXT',
                                                                                                      'l_current_timestamp'))) = 'L'
                  UNION
                  -- FUTURE ENCOUNTERS
                  SELECT id_epis_encounter,
                         id_episode,
                         dt_create,
                         dt_epis_encounter,
                         flg_status,
                         flg_type,
                         'F' flg_encounter_status,
                         id_professional,
                         6 rank_image
                    FROM (SELECT ee.id_epis_encounter,
                                 ee.id_episode,
                                 ee.dt_create,
                                 ee.dt_epis_encounter,
                                 ee.flg_status,
                                 ee.flg_type,
                                 ee.id_professional,
                                 row_number() over(PARTITION BY ee.id_episode ORDER BY ee.dt_epis_encounter) rn
                            FROM epis_encounter ee
                           WHERE pk_date_utils.compare_dates_tsz(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                              sys_context('ALERT_CONTEXT',
                                                                                          'i_prof_institution'),
                                                                              sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                                 pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT',
                                                                                                                           'l_prof_id'),
                                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                                           'l_prof_institution'),
                                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                                           'l_prof_software')),
                                                                                                  ee.dt_epis_encounter),
                                                                 pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT',
                                                                                                                           'l_prof_id'),
                                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                                           'l_prof_institution'),
                                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                                           'l_prof_software')),
                                                                                                  sys_context('ALERT_CONTEXT',
                                                                                                              'l_current_timestamp'))) = 'G'
                             AND ee.flg_status = 'R'
                             AND NOT EXISTS
                           (SELECT 1
                                    FROM epis_encounter ee1
                                   WHERE ee1.id_episode = ee.id_episode
                                     AND ee1.dt_epis_encounter BETWEEN sys_context('ALERT_CONTEXT', 'l_dt_begin') AND
                                         sys_context('ALERT_CONTEXT', 'l_dt_end')
                                     AND ee1.flg_status IN ('R', 'A', 'C', 'I')))
                   WHERE rn = 1
                  UNION
                  -- EPISODE THAT DON'T HAVE AN ENCOUNTER
                SELECT DISTINCT NULL id_epis_encounter,
                                ee.id_episode,
                                NULL dt_create,
                                NULL dt_epis_encounter,
                                NULL flg_status,
                                NULL flg_type,
                                'N' flg_encounter_status,
                                NULL id_professional,
                                6 rank_image
                  FROM epis_encounter ee
                 WHERE ee.flg_status != 'R'
                   AND NOT EXISTS
                 (SELECT 1
                          FROM epis_encounter ee1
                         WHERE ee1.id_episode = ee.id_episode
                           AND ee1.flg_status IN ('R', 'A', 'C', 'I')
                           AND ee1.dt_epis_encounter BETWEEN sys_context('ALERT_CONTEXT', 'l_dt_begin') AND
                               sys_context('ALERT_CONTEXT', 'l_dt_end')
                        UNION
                        SELECT 1
                          FROM epis_encounter ee1
                         WHERE ee1.id_episode = ee.id_episode
                           AND ee1.flg_status IN ('R', 'A')
                           AND pk_date_utils.compare_dates_tsz(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                            sys_context('ALERT_CONTEXT',
                                                                                        'i_prof_institution'),
                                                                            sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                               pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT',
                                                                                                                         'l_prof_id'),
                                                                                                             sys_context('ALERT_CONTEXT',
                                                                                                                         'l_prof_institution'),
                                                                                                             sys_context('ALERT_CONTEXT',
                                                                                                                         'l_prof_software')),
                                                                                                ee1.dt_epis_encounter),
                                                               pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT',
                                                                                                                         'l_prof_id'),
                                                                                                             sys_context('ALERT_CONTEXT',
                                                                                                                         'l_prof_institution'),
                                                                                                             sys_context('ALERT_CONTEXT',
                                                                                                                         'l_prof_software')),
                                                                                                sys_context('ALERT_CONTEXT',
                                                                                                            'l_current_timestamp'))) = 'G')) ec,
               epis_encounter_reason ecr,
               opinion o
         WHERE e.id_epis_type = 19
           AND e.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND e.flg_status NOT IN ('C', 'I')
           AND e.id_episode = ec.id_episode
           AND sys_context('ALERT_CONTEXT', 'i_prof_id') IN
               (ec.id_professional,
                (SELECT column_value id_prof
                   FROM TABLE(pk_hand_off_api.get_responsibles_id(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                  profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                               sys_context('ALERT_CONTEXT',
                                                                                           'i_prof_institution'),
                                                                               sys_context('ALERT_CONTEXT',
                                                                                           'i_prof_software')),
                                                                  e.id_episode,
                                                                  sys_context('ALERT_CONTEXT', 'l_prof_cat'),
                                                                  sys_context('ALERT_CONTEXT', 'l_handoff_type')))))
           AND ec.id_epis_encounter = ecr.id_epis_encounter(+)
           AND e.id_episode = o.id_episode_answer
           AND o.flg_state = 'E')
 GROUP BY sql_rn,
          id_episode,
          id_patient,
          id_epis_encounter,
          flg_type,
          flg_status,
          flg_encounter_status,
          dt_epis_encounter,
          id_prof_questions,
          id_opinion,
          o_id_episode,
          rank_image;
