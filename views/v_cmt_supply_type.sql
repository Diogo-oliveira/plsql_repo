CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SUPPLY_TYPE AS
SELECT "DESC_SUPPLY_TYPE","ID_CNT_SUPPLY_TYPE","DESC_SUPPLY_TYPE_PARENT","ID_CNT_SUPPLY_TYPE_PARENT"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), st.code_supply_type)
                  FROM dual) desc_supply_type,
               st.id_content id_cnt_supply_type,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      (SELECT code_supply_type
                                                         FROM alert.supply_type
                                                        WHERE id_supply_type = st.id_parent))
                  FROM dual) desc_supply_type_parent,
               (SELECT id_content
                  FROM alert.supply_type
                 WHERE id_supply_type = st.id_parent) id_cnt_supply_type_parent
          FROM alert.supply_type st
         WHERE st.flg_available = 'Y')
 WHERE desc_supply_type IS NOT NULL
 ORDER BY 1 ASC;

