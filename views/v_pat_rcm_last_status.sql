-- criar view de pat_reminders para saber a data da ultima alteracao de estado para a recomendacao (a utilizar pelos CDRs)
CREATE OR REPLACE VIEW V_PAT_RCM_LAST_STATUS AS
SELECT t.id_patient, t.id_rcm, t.id_rcm_det, t.dt_status, t.id_institution
  FROM (SELECT row_number() over(PARTITION BY prd.id_patient, prd.id_rcm ORDER BY prh.dt_status DESC) my_row,
               prd.id_rcm,
               prd.id_rcm_det,
							 prd.id_institution,
               prh.dt_status,
               prh.id_status,
               prd.id_patient
          FROM pat_rcm_det prd
          JOIN pat_rcm_h prh
            ON (prd.id_patient = prh.id_patient AND prd.id_rcm = prh.id_rcm AND prd.id_rcm_det = prh.id_rcm_det and prd.id_institution = prh.id_institution)) t
 WHERE t.my_row = 1
   AND t.id_status != 80;