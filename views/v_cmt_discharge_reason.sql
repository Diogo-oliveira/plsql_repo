CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DISCHARGE_REASON AS
SELECT "DESC_DISCHARGE_REASON", "ID_CNT_DISCHARGE_REASON", "ID_DISCHARGE_REASON"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      a.code_discharge_reason)
                  FROM dual) desc_discharge_reason,
               a.id_content id_cnt_discharge_reason,
               id_discharge_reason
          FROM alert.discharge_reason a
         WHERE a.flg_available = 'Y')
 WHERE desc_discharge_reason IS NOT NULL;

