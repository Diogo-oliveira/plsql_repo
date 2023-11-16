CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_EXTERNAL_CAUSE AS
SELECT "DESC_EXTERNAL_CAUSE", "ID_CNT_EXTERNAL_CAUSE", "RANK"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_external_cause)
                  FROM dual) desc_external_cause,
               id_content id_cnt_external_cause,
               rank
          FROM alert.external_cause a
         WHERE a.flg_available = 'Y')
 WHERE desc_external_cause IS NOT NULL;

