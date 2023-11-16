-- criar view de pat_reminders para saber a data da ultima geracao de reminder por paciente
CREATE OR REPLACE VIEW V_PAT_RCM_DET AS
SELECT t.id_patient, t.id_rcm, t.dt_create, t.id_institution
  FROM (SELECT row_number() over(PARTITION BY prd.id_patient, prd.id_rcm ORDER BY prd.id_rcm_det DESC) my_row,
               prd.id_rcm,
							 prd.id_institution,
               prd.id_rcm_det,
               prd.id_patient,
               prd.dt_create
          FROM pat_rcm_det prd) t
 WHERE t.my_row = 1;
