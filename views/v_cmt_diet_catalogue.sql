CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DIET_CATALOGUE AS
SELECT DISTINCT desc_diet,
                id_cnt_diet,
                desc_diet_type,
                id_diet_type,
                desc_diet_parent,
                id_cnt_diet_parent,
                rank,
                quantity_default,
                desc_unit_measure,
                id_unit_measure,
                energy_quantity_value,
                desc_unit_measure_energy,
                id_unit_measure_energy,
                id_diet
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_diet)
                  FROM dual) desc_diet,
               a.id_content id_cnt_diet,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), dt.code_diet_type)
                  FROM dual) desc_diet_type,
               a.id_diet_type id_diet_type,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), b.code_diet)
                  FROM dual) desc_diet_parent,
               b.id_content id_cnt_diet_parent,
               a.rank,
               a.quantity_default,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), d.code_unit_measure)
                  FROM dual) desc_unit_measure,
               d.id_unit_measure,
               a.energy_quantity_value,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), e.code_unit_measure)
                  FROM dual) desc_unit_measure_energy,
               e.id_unit_measure id_unit_measure_energy,
               a.id_diet
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
         WHERE a.flg_available = 'Y')
 WHERE desc_diet IS NOT NULL
 ORDER BY 1;

