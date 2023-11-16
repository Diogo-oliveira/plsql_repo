CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_LOC_DEFAULT AS
SELECT "DESC_SUPPLY","ID_CNT_SUPPLY","DESC_SUPPLY_LOCATION","ID_SUPPLY_LOCATION","FLG_DEFAULT"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), su.code_supply)
                  FROM dual) desc_supply,
               su.id_content id_cnt_supply,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      sl.code_supply_location)
                  FROM dual) desc_supply_location,
               sl.id_supply_location,
               sld.flg_default
          FROM alert.supply su
         INNER JOIN alert.supply_soft_inst ssi
            ON ssi.id_supply = su.id_supply
         INNER JOIN alert.supply_type st
            ON st.id_supply_type = su.id_supply_type
         INNER JOIN alert.supply_loc_default sld
            ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
         INNER JOIN alert.supply_location sl
            ON sl.id_supply_location = sld.id_supply_location
         WHERE su.flg_available = 'Y'
           AND ssi.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND ssi.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
 WHERE desc_supply IS NOT NULL;

