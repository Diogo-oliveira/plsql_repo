CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_S AS
SELECT "DESC_SUPPLY","ID_CNT_SUPPLY","DESC_SUPPLY_TYPE","ID_CNT_SUPPLY_TYPE","FLG_TYPE"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), su.code_supply)
                  FROM dual) desc_supply,
               su.id_content id_cnt_supply,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), st.code_supply_type)
                  FROM dual) desc_supply_type,
               st.id_content id_cnt_supply_type,
               su.flg_type
          FROM alert.supply su
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'SUPPLY.CODE_SUPPLY')) t
            ON t.code_translation = su.code_supply
         INNER JOIN alert.supply_type st
            ON st.id_supply_type = su.id_supply_type
         WHERE su.flg_available = 'Y'
           AND NOT EXISTS (SELECT 1
                  FROM alert.supply_soft_inst ssi
                 WHERE su.id_supply = ssi.id_supply
                   AND ssi.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND ssi.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')))
 WHERE desc_supply IS NOT NULL;

