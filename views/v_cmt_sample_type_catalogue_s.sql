CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SAMPLE_TYPE_CATALOGUE_S AS
SELECT DISTINCT desc_sample_type, desc_alias, id_cnt_sample_type, id_sample_type
  FROM (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_sample_type) desc_sample_type,
               a.id_content id_cnt_sample_type,
               a.id_sample_type,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      alert.pk_lab_tests_utils.get_alias_code_translation(sys_context('ALERT_CONTEXT',
                                                                                                                      'ID_LANGUAGE'),
                                                                                                          profissional(0,
                                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                                   'ID_INSTITUTION'),
                                                                                                                       sys_context('ALERT_CONTEXT',
                                                                                                                                   'ID_SOFTWARE')),
                                                                                                          'S',
                                                                                                          a.code_sample_type,
                                                                                                          NULL))
                  FROM dual) desc_alias
          FROM alert.sample_type a
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'SAMPLE_TYPE.CODE_SAMPLE_TYPE')) t
            ON t.code_translation = a.code_sample_type
         WHERE a.flg_available = 'N')
 WHERE desc_sample_type IS NOT NULL
 ORDER BY 1;

