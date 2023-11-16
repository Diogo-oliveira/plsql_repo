CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SAMPLE_RECIPIENT_CTLG AS
SELECT DISTINCT desc_sample_recipient, id_cnt_sample_recipient, id_sample_recipient
  FROM (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_sample_recipient) desc_sample_recipient,
               a.id_content id_cnt_sample_recipient,
               a.id_sample_recipient
          FROM alert.sample_recipient a
         WHERE a.flg_available = 'Y')
 WHERE desc_sample_recipient IS NOT NULL
 ORDER BY 1;

