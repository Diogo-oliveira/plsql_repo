CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_CATALOGUE AS
SELECT DISTINCT desc_supply, id_cnt_supply, desc_supply_type, id_cnt_supply_type, flg_type, id_supply
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), su.code_supply)
                  FROM dual) desc_supply,
               su.id_content id_cnt_supply,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), st.code_supply_type)
                  FROM dual) desc_supply_type,
               st.id_content id_cnt_supply_type,
               su.flg_type,
               su.id_supply
          FROM alert.supply su
         INNER JOIN alert.supply_type st
            ON st.id_supply_type = su.id_supply_type
         WHERE su.flg_available = 'Y')
 WHERE desc_supply IS NOT NULL;

