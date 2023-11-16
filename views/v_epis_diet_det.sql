CREATE OR REPLACE VIEW V_EPIS_DIET_DET AS
SELECT edd.id_epis_diet_det,
       edd.id_epis_diet_req,
       edd.notes,
       edd.id_diet_schedule,
       ds.code_diet_schedule,
       edd.dt_diet_schedule,
       edd.id_diet,       
       edd.quantity,
       edd.id_unit_measure
  FROM epis_diet_det edd
  JOIN diet_schedule ds
    ON ds.id_diet_schedule = edd.id_diet_schedule;





