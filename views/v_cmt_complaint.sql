CREATE OR REPLACE VIEW V_CMT_COMPLAINT AS
SELECT "DESC_COMPLAINT", "ID_COMPLAINT", "ID_CNT_COMPLAINT"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_complaint)
                  FROM dual) desc_complaint,
               a.id_complaint,
               a.id_content id_cnt_complaint
          FROM complaint a
         WHERE a.flg_available = 'Y')
 WHERE desc_complaint IS NOT NULL
 ORDER BY 1 ASC;
