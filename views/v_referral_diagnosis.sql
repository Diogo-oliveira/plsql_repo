CREATE OR REPLACE VIEW V_REFERRAL_DIAGNOSIS AS
SELECT pd.id_external_request,
       pk_sysdomain.get_domain('DIAGNOSIS.FLG_TYPE', d.flg_type, 1) diag_type,
       d.flg_type flg_diag_type,
       code_icd,
       pk_translation.get_translation(1, d.code_diagnosis) desc_diagnosis,
       pd.flg_type,
       null dt_begin,
           NULL dt_end,
           NULL notes,
           NULL flg_status,
			 decode(pd.flg_type,'P',p.year_begin,NULL) year_begin,
			 decode(pd.flg_type,'P',p.month_begin,NULL) month_begin,
			 decode(pd.flg_type,'P',p.day_begin,NULL) day_begin
  FROM p1_exr_diagnosis pd
  JOIN diagnosis d ON pd.id_diagnosis = d.id_diagnosis
  JOIN p1_external_request p ON (p.id_external_request = pd.id_external_request)
 WHERE pd.flg_status = 'A'
   --restriction for A - answers, D - diagnosis, P - problems
   AND pd.flg_type IN ('A', 'D', 'P');