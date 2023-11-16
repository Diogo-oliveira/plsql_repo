CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_LOCATION AS
SELECT "DESC_SUPPLY_LOCATION","ID_SUPPLY_LOCATION","STOCK_TYPE","CAT_WORKFLOW"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      sl.code_supply_location)
                  FROM dual) desc_supply_location,
               sl.id_supply_location,
               (SELECT a.desc_val
                  FROM sys_domain a
                 WHERE a.code_domain = 'SUPPLY_LOCATION.FLG_STOCK_TYPE'
                   AND a.val = sl.flg_stock_type
                   AND id_language = sys_context('ALERT_CONTEXT', 'ID_LANGUAGE')) stock_type,
               (SELECT a.desc_val
                  FROM sys_domain a
                 WHERE a.code_domain = 'SUPPLY_LOCATION.FLG_CAT_WORKFLOW'
                   AND a.val = sl.flg_cat_workflow
                   AND id_language = sys_context('ALERT_CONTEXT', 'ID_LANGUAGE')) cat_workflow
          FROM alert.supply_location sl)
 WHERE desc_supply_location IS NOT NULL
 ORDER BY 1 ASC;

