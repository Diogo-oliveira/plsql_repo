CREATE OR REPLACE VIEW v_analysis_loinc AS
SELECT al.id_analysis_loinc,
       al.id_analysis,
       al.loinc_code,
       al.id_institution,
       al.id_software,
       al.flg_default,
       al.id_sample_type
  FROM analysis_loinc al
 WHERE al.flg_default = 'Y';
