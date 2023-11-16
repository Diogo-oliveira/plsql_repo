CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DIET AS
SELECT "DESC_DIET",
       "ID_CNT_DIET",
       "ID_DIET",
       "DESC_DIET_TYPE",
       "ID_DIET_TYPE",
       "DESC_DIET_PRT",
       "ID_CNT_DIET_PRT",
       "RANK",
       "QUANTITY_DEFAULT",
       "DESC_UNIT_MEASURE",
       "ID_UNIT_MEASURE",
       "ENERGY_QUANTITY_VALUE",
       "DESC_UNIT_MEASURE_ENERGY",
       "ID_UNIT_MEASURE_ENERGY"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_diet)
                  FROM dual) desc_diet,
               a.id_content id_cnt_diet,
               a.id_diet,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), dt.code_diet_type)
                  FROM dual) desc_diet_type,
               a.id_diet_type id_diet_type,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), b.code_diet)
                  FROM dual) desc_diet_prt,
               b.id_content id_cnt_diet_prt,
               a.rank,
               a.quantity_default,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), d.code_unit_measure)
                  FROM dual) desc_unit_measure,
               d.id_unit_measure,
               a.energy_quantity_value,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_unit_measure)
                  FROM dual) desc_unit_measure_energy,
               e.id_unit_measure id_unit_measure_energy
          FROM diet a
          LEFT JOIN diet b
            ON a.id_diet_parent = b.id_diet
           AND b.flg_available = 'Y'
          LEFT JOIN unit_measure d
            ON d.id_unit_measure = a.id_unit_measure
          LEFT JOIN unit_measure e
            ON e.id_unit_measure = a.id_unit_measure_energy
          LEFT JOIN diet_type dt
            ON dt.id_diet_type = a.id_diet_type
           AND dt.flg_available = 'Y'
         WHERE a.flg_available = 'Y'
           AND EXISTS (SELECT 1
                  FROM diet_instit_soft c
                 WHERE c.id_institution IN (sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'), 0)
                   AND c.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'), 0)
                   AND c.flg_available = 'Y'
                   AND c.id_diet = a.id_diet))
 WHERE desc_diet IS NOT NULL
 ORDER BY 1;

