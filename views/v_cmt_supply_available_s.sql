CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_AVAILABLE_S AS
SELECT DISTINCT desc_supply,
                id_cnt_supply,
                flg_type,
                nvl(flg_cons_type, 'C') flg_cons_type,
                nvl(flg_reusable, 'N') flg_reusable,
                id_unit_measure,
                nvl(flg_editable, 'N') flg_editable,
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
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'SUPPLY.CODE_SUPPLY')) t
            ON t.code_translation = su.code_supply
          LEFT JOIN alert.supply_soft_inst ssi
            ON ssi.id_supply = su.id_supply
           AND ssi.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND ssi.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
          LEFT JOIN alert.supply_sup_area ssa
            ON ssa.id_supply_soft_inst = ssi.id_supply_soft_inst
           AND ssa.flg_available = 'Y'
          LEFT JOIN alert.supply_area sa
            ON sa.id_supply_area = ssa.id_supply_area
          LEFT JOIN alert.supply_loc_default sld
            ON sld.id_supply_soft_inst = ssi.id_supply_soft_inst
          LEFT JOIN alert.supply_location sl
            ON sl.id_supply_location = sld.id_supply_location
           AND sl.id_institution IN (0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
         WHERE su.flg_available = 'Y')
 WHERE desc_supply IS NOT NULL
   AND rn = 1
   AND (id_supply_area IS NULL OR id_supply_location IS NULL OR flg_cons_type IS NULL)
 ORDER BY desc_supply, id_supply_location;

