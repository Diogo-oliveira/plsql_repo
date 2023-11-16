CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_AREA AS
SELECT "DESC_SUPPLY_AREA","ID_SUPPLY_AREA"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sa.code_supply_area)
                  FROM dual) desc_supply_area,
               sa.id_supply_area
          FROM alert.supply_area sa)
 WHERE desc_supply_area IS NOT NULL
 ORDER BY 1 ASC;

