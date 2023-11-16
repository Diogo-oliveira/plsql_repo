CREATE OR REPLACE VIEW V_GLOBAL_SEARCH_LIST AS
    SELECT t3.id_patient,
           t3.id_episode,
           t3.dt_start_episode,
           t3.id_epis_type,
           t3.id_language,
           t3.id_task_type,
           t3.desc_task_type,
           t3.code_translations,
           t3.num_recs
      FROM (SELECT t1.id_patient,
                   t1.id_episode,
                   t1.dt_begin_tstz dt_start_episode,
                   t1.id_epis_type,
                   t1.id_language,
                   COUNT(DISTINCT t1.id_task_type) num_recs,
                   CAST(COLLECT(DISTINCT to_char(t1.id_task_type)) AS table_varchar) id_task_type,
                   CAST(COLLECT(DISTINCT pk_translation.get_translation(t1.id_language,
                                                               'TASK_TYPE.CODE_TASK_TYPE.' || t1.id_task_type)) AS
                        table_varchar) desc_task_type,
                   CAST(COLLECT(t1.code_translation) AS table_varchar) code_translations
              FROM (SELECT /*+ opt_estimate (table t, rows=1)*/
                     t.id_patient id_patient,
                     t.id_episode id_episode,
                     epis.dt_begin_tstz dt_begin_tstz,
                     vis.id_institution,
                     epis.id_epis_type,
                     tt.id_language id_language,
                     t.id_task_type id_task_type,
                     pk_translation.get_translation(tt.id_language, 'TASK_TYPE.CODE_TASK_TYPE.' || t.id_task_type) inner_desc_tt,
                     t.code_translation
                      FROM TABLE(pk_core_translation.get_search_translation_trs(i_lang        => sys_context('ALERT_CONTEXT',
                                                                                                             'i_lang'),
                                                                                i_search      => sys_context('ALERT_CONTEXT',
                                                                                                             'i_search_text'),
                                                                                i_owner       => NULL,
                                                                                i_column_name => NULL)) t
                      join translation_trs tt on tt.code_translation = t.code_translation
                      LEFT OUTER JOIN episode epis
                        ON epis.id_episode = t.id_episode
                      LEFT OUTER JOIN visit vis
                        ON vis.id_visit = epis.id_visit
                     WHERE vis.id_institution = sys_context('ALERT_CONTEXT', 'i_id_institution')
                       AND epis.id_epis_type IN (SELECT id_epis_type
                                                   FROM epis_type et
                                                   JOIN tbl_temp tt
                                                     ON tt.num_1 = et.id_epis_type
                                                  WHERE tt.num_1 IS NOT NULL)
                          
                       AND t.id_task_type IN (SELECT id_task_type
                                                FROM task_type et
                                                JOIN tbl_temp tt
                                                  ON tt.num_2 = et.id_task_type
                                               WHERE tt.num_2 IS NOT NULL)
                       AND t.dt_record BETWEEN
                           pk_date_utils.get_string_tstz(i_lang      => sys_context('ALERT_CONTEXT', 'i_lang'),
                                                         i_prof      => profissional(sys_context('ALERT_CONTEXT',
                                                                                                 'i_id_prof'),
                                                                                     sys_context('ALERT_CONTEXT',
                                                                                                 'i_id_institution'),
                                                                                     sys_context('ALERT_CONTEXT',
                                                                                                 'i_id_software')),
                                                         i_timestamp => sys_context('ALERT_CONTEXT', 'i_dt_begin'),
                                                         i_timezone  => NULL) AND
                           pk_date_utils.get_string_tstz(i_lang      => sys_context('ALERT_CONTEXT', 'i_lang'),
                                                         i_prof      => profissional(sys_context('ALERT_CONTEXT',
                                                                                                 'i_id_prof'),
                                                                                     sys_context('ALERT_CONTEXT',
                                                                                                 'i_id_institution'),
                                                                                     sys_context('ALERT_CONTEXT',
                                                                                                 'i_id_software')),
                                                         i_timestamp => sys_context('ALERT_CONTEXT', 'i_dt_end'),
                                                         i_timezone  => NULL)
                     ORDER BY pk_translation.get_translation(tt.id_language, 'TASK_TYPE.CODE_TASK_TYPE.' || t.id_task_type)) t1
             GROUP BY t1.id_patient, t1.id_episode, t1.id_epis_type, t1.id_language, t1.dt_begin_tstz) t3
     ORDER BY 3 DESC;