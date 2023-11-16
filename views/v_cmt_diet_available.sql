CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DIET_AVAILABLE AS
SELECT desc_diet, id_cnt_diet
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_diet)
                  FROM dual) desc_diet,
               a.id_content id_cnt_diet
          FROM diet a
          JOIN diet_instit_soft c
            ON c.id_diet = a.id_diet
           AND c.id_institution IN (sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'), 0)
           AND c.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'), 0)
           AND c.flg_available = 'Y'
         WHERE a.flg_available = 'Y')
 WHERE desc_diet IS NOT NULL
 ORDER BY 1;

