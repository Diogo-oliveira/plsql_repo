CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DISCHARGE_DESTINATION AS
SELECT "DESC_DISCHARGE_DESTINATION", "ID_CNT_DISCHARGE_DESTINATION", "ID_DISCHARGE_DESTINATION"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_discharge_dest)
                  FROM dual) desc_discharge_destination,
               a.id_content id_cnt_discharge_destination,
               id_discharge_dest AS id_discharge_destination
          FROM alert.discharge_dest a
         WHERE a.flg_available = 'Y')
 WHERE desc_discharge_destination IS NOT NULL;

