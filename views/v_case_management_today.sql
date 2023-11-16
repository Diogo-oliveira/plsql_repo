CREATE OR REPLACE VIEW v_case_management_today AS
SELECT sql_rn,
       id_episode,
       id_patient,
       id_epis_encounter,
       flg_type,
       flg_status,
       NULL flg_encounter_status,
       dt_epis_encounter,
       id_prof_questions,
       id_opinion,
       id_episode o_id_episode,
       substr(concatenate(pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                         'REASON_ENCOUNTER.CODE_REASON.' || id_reason) || '; '),
              1,
              length(concatenate(pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                'REASON_ENCOUNTER.CODE_REASON.' || id_reason) || '; ')) - 2) encounter_reason,
       NULL rank_image
  FROM (SELECT 1                    sql_rn,
               e.id_episode,
               e.id_patient,
               ec.id_epis_encounter,
               ec.flg_type,
               ec.flg_status,
               ec.dt_epis_encounter,
               o.id_prof_questions,
               o.id_opinion,
               o.id_episode         o_id_episode,
               ecr.id_reason
          FROM episode e, epis_encounter ec, epis_encounter_reason ecr, opinion o
         WHERE e.id_epis_type = 19
           AND e.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND e.flg_status NOT IN ('C', 'I')
           AND e.id_episode = ec.id_episode
           AND ec.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
           AND ec.dt_epis_encounter BETWEEN sys_context('ALERT_CONTEXT', 'l_dt_begin') AND
               sys_context('ALERT_CONTEXT', 'l_dt_end')
           AND ec.flg_status IN ('R', 'A', 'C', 'I')
           AND ec.id_epis_encounter = ecr.id_epis_encounter(+)
           AND e.id_episode = o.id_episode_answer
        UNION ALL
        SELECT 2                    sql_rn,
               e.id_episode,
               e.id_patient,
               ec.id_epis_encounter,
               ec.flg_type,
               ec.flg_status,
               ec.dt_epis_encounter,
               o.id_prof_questions,
               o.id_opinion,
               o.id_episode         o_id_episode,
               ecr.id_reason
          FROM episode e, epis_encounter ec, epis_encounter_reason ecr, opinion o
         WHERE e.id_epis_type = 19
           AND e.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND e.flg_status NOT IN ('C', 'I')
           AND e.id_episode = ec.id_episode
           AND ec.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
           AND ec.flg_status IN ('R', 'A')
           AND pk_date_utils.compare_dates_tsz(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                            sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                            sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                               pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT',
                                                                                                         'l_prof_id'),
                                                                                             sys_context('ALERT_CONTEXT',
                                                                                                         'l_prof_institution'),
                                                                                             sys_context('ALERT_CONTEXT',
                                                                                                         'l_prof_software')),
                                                                                ec.dt_epis_encounter),
                                               sys_context('ALERT_CONTEXT', 'l_dt_begin')) = 'L'
           AND ec.id_epis_encounter = ecr.id_epis_encounter(+)
           AND e.id_episode = o.id_episode_answer)
 GROUP BY sql_rn,
          id_episode,
          id_patient,
          id_epis_encounter,
          flg_type,
          flg_status,
          dt_epis_encounter,
          id_prof_questions,
          id_opinion,
          o_id_episode;
