CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_RELATION AS
SELECT "DESC_SUPPLY","ID_CNT_SUPPLY","DESC_SUPPLY_ITEM","ID_CNT_SUPPLY_ITEM","QUANTITY"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), su.code_supply)
                  FROM dual) desc_supply,
               su.id_content id_cnt_supply,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), i.code_supply)
                  FROM dual) desc_supply_item,
               i.id_content id_cnt_supply_item,
               sr.quantity
          FROM alert.supply su
         INNER JOIN supply_relation sr
            ON sr.id_supply = su.id_supply
         INNER JOIN alert.supply i
            ON i.id_supply = sr.id_supply_item
         WHERE su.flg_available = 'Y'
           AND i.flg_available = 'Y')
 WHERE desc_supply IS NOT NULL
   AND desc_supply_item IS NOT NULL;

