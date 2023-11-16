CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_SUP_AREA AS
SELECT "DESC_SUPPLY","ID_CNT_SUPPLY","DESC_SUPPLY_AREA","ID_SUPPLY_AREA"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), su.code_supply)
                  FROM dual) desc_supply,
               su.id_content id_cnt_supply,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sl.code_supply_area)
                  FROM dual) desc_supply_area,
               sl.id_supply_area
          FROM alert.supply su
         INNER JOIN alert.supply_soft_inst ssi
            ON ssi.id_supply = su.id_supply
         INNER JOIN alert.supply_sup_area ssa
            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
         INNER JOIN alert.supply_area sl
            ON sl.id_supply_area = ssa.id_supply_area
         WHERE su.flg_available = 'Y'
           AND ssi.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND ssi.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
 WHERE desc_supply IS NOT NULL;

