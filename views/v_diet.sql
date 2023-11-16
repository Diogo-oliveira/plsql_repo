CREATE OR REPLACE VIEW V_DIET AS
SELECT d.id_diet,
       d.code_diet,
       d.id_diet_parent,
       d.flg_available,
       d.id_diet_type,
       dt.code_diet_type,
       d.quantity_default,
       d.id_unit_measure,
       d.energy_quantity_value,
       d.id_unit_measure_energy,
       d.id_content,
	   d.rank
  FROM diet d
  JOIN diet_type dt
    ON dt.id_diet_type = d.id_diet_type;