CREATE OR REPLACE VIEW V_EXAM_DIAGNOSIS AS
SELECT id_mcdt_req_diagnosis,
       mrd.id_diagnosis,
       id_exam_req,
       id_exam_req_det,
       flg_status,
       id_prof_cancel,
       dt_cancel_tstz,
       code_icd,
       flg_type,
       code_diagnosis,
       mdm_coding,
       id_content
  FROM mcdt_req_diagnosis mrd
  JOIN diagnosis d ON mrd.id_diagnosis = d.id_diagnosis
 WHERE id_exam_req IS NOT NULL
   AND id_exam_req_det IS NOT NULL;
