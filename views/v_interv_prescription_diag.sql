CREATE OR REPLACE VIEW V_INTERV_PRESCRIPTION_DIAG AS
SELECT id_mcdt_req_diagnosis,
       mrd.id_diagnosis,
       id_interv_prescription,
       id_interv_presc_det,
       flg_status,
       id_prof_cancel,
       dt_cancel_tstz,
       code_icd,
       flg_type,
       code_diagnosis,
       mdm_coding,
       id_content,
       mrd.id_alert_diagnosis
  FROM mcdt_req_diagnosis mrd
  JOIN diagnosis d ON mrd.id_diagnosis = d.id_diagnosis
 WHERE id_interv_prescription IS NOT NULL
   AND id_interv_presc_det IS NOT NULL;
