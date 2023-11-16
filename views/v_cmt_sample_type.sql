CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SAMPLE_TYPE AS
SELECT desc_sample_type, id_cnt_sample_type, id_sample_type
  FROM (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_sample_type) desc_sample_type,
               a.id_content id_cnt_sample_type,
               a.id_sample_type
          FROM alert.sample_type a
         WHERE a.flg_available = 'Y')
 WHERE desc_sample_type IS NOT NULL
 ORDER BY 1;

