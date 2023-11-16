CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROCEDURE_CATEGORY AS
SELECT desc_procedure_cat, id_cnt_procedure_cat, rank
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      ic.code_interv_category)
                  FROM dual) desc_procedure_cat,
               ic.id_content id_cnt_procedure_cat,
               ic.rank
          FROM alert.interv_category ic
         WHERE ic.flg_available = 'Y')
 WHERE desc_procedure_cat IS NOT NULL;

