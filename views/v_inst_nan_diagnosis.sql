-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 03/11/2014 09:11
-- CHANGE REASON: [ALERT_290969] Nursing Care Plan: NANDA, NIC, NOC - Views
CREATE OR REPLACE VIEW V_INST_NAN_DIAGNOSIS AS
  SELECT si.id_institution,
         si.id_software,
         t.id_nan_cfg_diagnosis,
         t.flg_status,
         t.dt_last_update,
         t.id_nan_diagnosis,
         t.id_terminology_version,
         t.diagnosis_code,
         t.code_name,
         t.code_definition,
         t.year_approved,
         t.year_revised,
         t.loe,
         t.references,
         t.id_nan_class,
         t.id_language,
         CAST(MULTISET (SELECT ndc.id_nan_def_chars
                 FROM nan_def_chars ndc
                WHERE ndc.id_nan_diagnosis = t.id_nan_diagnosis) AS table_number) lst_def_chars,
         CAST(MULTISET (SELECT rskf.id_nan_risk_factor
                 FROM nan_risk_factor rskf
                WHERE rskf.id_nan_diagnosis = t.id_nan_diagnosis) AS table_number) lst_risk_factors,
         CAST(MULTISET (SELECT relf.id_nan_related_factor
                 FROM nan_related_factor relf
                WHERE relf.id_nan_diagnosis = t.id_nan_diagnosis) AS table_number) lst_rel_factors
    FROM software_institution si,
         TABLE(pk_nan_cfg.tf_inst_diagnosis(i_inst => si.id_institution, i_soft => si.id_software)) t;
/
-- CHANGE END: Ariel Machado
