CREATE OR REPLACE VIEW V_CMT_COMPLAINT_ALIAS AS
SELECT "DESC_COMPLAINT_ALIAS", "ID_COMPLAINT_ALIAS", "ID_CNT_COMPLAINT_ALIAS", "ID_CNT_COMPLAINT", "ID_COMPLAINT"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_complaint_alias)
                  FROM dual) desc_complaint_alias,
               a.id_complaint_alias,
               a.id_content id_cnt_complaint_alias,
               c.id_content id_cnt_complaint,
               c.id_complaint
          FROM complaint_alias a
          JOIN complaint c
            ON c.id_complaint = a.id_complaint
           AND c.flg_available = 'Y'
         WHERE a.flg_available = 'Y')
 WHERE desc_complaint_alias IS NOT NULL
 ORDER BY 1 ASC;
