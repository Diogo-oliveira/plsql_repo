CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SAMPLE_TYPE_S AS
SELECT desc_sample_type, id_cnt_sample_type, id_sample_type
  FROM (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_sample_type) desc_sample_type,
               a.id_content id_cnt_sample_type,
               a.id_sample_type
          FROM alert.sample_type a
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'SAMPLE_TYPE.CODE_SAMPLE_TYPE')) t
            ON t.code_translation = a.code_sample_type
         WHERE a.flg_available = 'N')
 WHERE desc_sample_type IS NOT NULL
 ORDER BY 1;

