CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY AS
SELECT "DESC_SUPPLY",
       "ID_CNT_SUPPLY",
       "DESC_SUPPLY_TYPE",
       "ID_CNT_SUPPLY_TYPE",
       "FLG_TYPE",
       "FLG_CONS_TYPE",
       "FLG_REUSABLE",
       "ID_UNIT_MEASURE",
       "FLG_EDITABLE",
       "FLG_PREPARING",
       "FLG_COUNTABLE",
       "ID_SUPPLY"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), su.code_supply)
                  FROM dual) desc_supply,
               su.id_content id_cnt_supply,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), st.code_supply_type)
                  FROM dual) desc_supply_type,
               st.id_content id_cnt_supply_type,
               su.flg_type,
               ssi.flg_cons_type,
               ssi.flg_reusable,
               ssi.id_unit_measure,
               ssi.flg_editable,
               ssi.flg_preparing,
               ssi.flg_countable,
               su.id_supply
          FROM alert.supply su
         INNER JOIN alert.supply_soft_inst ssi
            ON ssi.id_supply = su.id_supply
         INNER JOIN alert.supply_type st
            ON st.id_supply_type = su.id_supply_type
         WHERE su.flg_available = 'Y'
           AND ssi.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND ssi.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
 WHERE desc_supply IS NOT NULL;

