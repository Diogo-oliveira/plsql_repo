CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_AVAILABLE AS
SELECT DISTINCT desc_supply,
                id_cnt_supply,
                id_supply,
                flg_type,
                flg_cons_type,
                flg_reusable,
                id_unit_measure,
                flg_editable,
                flg_preparing,
                flg_countable,
                desc_supply_area,
                id_supply_area,
                desc_supply_location,
                id_supply_location,
                flg_default_location
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), su.code_supply)
                  FROM dual) desc_supply,
               su.id_content id_cnt_supply,
               su.id_supply,
               su.flg_type,
               ssi.flg_cons_type,
               ssi.flg_reusable,
               ssi.id_unit_measure,
               ssi.flg_editable,
               ssi.flg_preparing,
               ssi.flg_countable,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sa.code_supply_area)
                  FROM dual) desc_supply_area,
               sa.id_supply_area,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      sl.code_supply_location)
                  FROM dual) desc_supply_location,
               sl.id_supply_location,
               sld.flg_default AS flg_default_location,
               row_number() over(PARTITION BY su.id_content ORDER BY sld.flg_default DESC) AS rn
          FROM alert.supply su
          JOIN alert.supply_soft_inst ssi
            ON ssi.id_supply = su.id_supply
           AND ssi.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND ssi.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
          JOIN alert.supply_sup_area ssa
            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
           AND ssa.flg_available = 'Y'
          JOIN alert.supply_area sa
            ON sa.id_supply_area = ssa.id_supply_area
          JOIN alert.supply_loc_default sld
            ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
          JOIN alert.supply_location sl
            ON sl.id_supply_location = sld.id_supply_location
           AND sl.id_institution IN (0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
         WHERE su.flg_available = 'Y')
 WHERE desc_supply IS NOT NULL
   AND rn = 1
 ORDER BY desc_supply, id_supply_location;

