CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SAMPLE_RECIPIENT_S AS
SELECT desc_sample_recipient, id_cnt_sample_recipient, id_sample_recipient
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      a.code_sample_recipient)
                  FROM dual) desc_sample_recipient,
               a.id_content id_cnt_sample_recipient,
               a.id_sample_recipient
          FROM alert.sample_recipient a
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT')) t
            ON t.code_translation = a.code_sample_recipient
         WHERE a.flg_available = 'N')
 WHERE desc_sample_recipient IS NOT NULL
 ORDER BY 1;

