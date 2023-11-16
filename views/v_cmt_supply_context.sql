CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_CONTEXT AS
SELECT "DESC_SUPPLY", "ID_CNT_SUPPLY", "FLG_CONTEXT", "ID_CONTEXT", "QUANTITY", "DESC_UNIT_MEASURE", "ID_UNIT_MEASURE"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), su.code_supply)
                  FROM dual) desc_supply,
               su.id_content id_cnt_supply,
               sc.flg_context,
               sc.id_context,
               sc.quantity,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), um.code_unit_measure)
                  FROM dual) desc_unit_measure,
               sc.id_unit_measure
          FROM alert.supply su
         INNER JOIN alert.supply_soft_inst ssi
            ON ssi.id_supply = su.id_supply
         INNER JOIN supply_context sc
            ON sc.id_supply = su.id_supply
           AND sc.id_institution = ssi.id_institution
           AND sc.id_software = ssi.id_software
          LEFT JOIN unit_measure um
            ON um.id_unit_measure = sc.id_unit_measure
         WHERE su.flg_available = 'Y'
           AND ssi.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND ssi.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
 WHERE desc_supply IS NOT NULL;

