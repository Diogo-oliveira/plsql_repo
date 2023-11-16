CREATE OR REPLACE VIEW V_REF_INTERNAL AS
SELECT v.id_dep_clin_serv,
       v.id_clinical_service,
       v.code_clinical_service,
       i_orig.id_institution,
       i_orig.flg_type inst_type,
       i_orig.code_institution,
       i_orig.ext_code,
       i_orig.abbreviation,
       v.id_department,
       v.code_department,
       v.dep_abbr,
       v.id_external_sys,
       v.id_dept,
       v.flg_availability,
       v.id_speciality,
       v.gender,
       v.age_min,
       v.age_max,
       v.code_speciality,
       pdi.flg_type
  FROM v_ref_spec_inst_dcs v
  JOIN p1_dest_institution pdi -- orig=dest (ref_dest_institution_spec not included - referrals created by dep_clin_serv)
    ON (v.id_institution = pdi.id_inst_dest)
  JOIN institution i_orig
    ON (i_orig.id_institution = v.id_institution AND i_orig.id_market = v.id_market)
 WHERE i_orig.flg_available = 'Y'
   AND v.flg_availability IN ('I', 'A') -- internal wf
   AND pdi.id_inst_orig = pdi.id_inst_dest
   AND v.flg_spec_dcs_default = 'Y' -- must have a matching id_speciality
;