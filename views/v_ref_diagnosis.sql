CREATE OR REPLACE VIEW V_REF_DIAGNOSIS AS
SELECT pd.id_external_request,
       pk_sysdomain.get_domain('DIAGNOSIS.FLG_TYPE', d.flg_type, 1) diag_type,
       code_icd,
       pk_translation.get_translation(1, d.code_diagnosis) desc_diagnosis,
       pd.flg_type,
       NULL dt_begin,
			 p.year_begin,
			 p.month_begin,
			 p.day_begin
  FROM p1_exr_diagnosis pd
  JOIN diagnosis d ON pd.id_diagnosis = d.id_diagnosis
  JOIN p1_external_request p ON (p.id_external_request = pd.id_external_request)
 WHERE pd.flg_status = 'A'
   AND pd.flg_type IN ('A', 'D', 'P');