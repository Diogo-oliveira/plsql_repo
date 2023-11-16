CREATE OR REPLACE VIEW V_REFERRAL_PAT AS
SELECT DISTINCT exr.id_patient id_patient,
                php.num_health_plan n_sns,
                m.sequential_number sequential_number,
                cr.num_clin_record,
                exr.id_inst_orig id_inst_orig,
                exr.id_inst_dest id_inst_dest,
                p.name name,
                p.gender gender,
                pk_sysdomain.get_domain('PATIENT.GENDER', p.gender, 1) gender_desc,
                p.dt_birth,
                psa.marital_status marital_status,
                pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, 1) desc_marital_status,
                i.id_isencao exemption_type,
                pk_translation.get_translation(1, i.code_isencao) exemption_type_desc,
                recm.id_recm id_recm,
                pk_translation.get_translation(1, recm.code_recm) desc_recm,
                NULL nics,
                psa.num_main_contact phone,
                psa.num_contact,
                psa.address address,
                psa.zip_code postal_code,
                psa.location locality,
                pk_translation.get_translation(1, d.code_district) district,
                psa.birth_place birth_place,
                pk_translation.get_translation(1, cn.code_country) desc_country_nationality,
                cn.alpha2_code code_country_nationality,
                pk_translation.get_translation(1, ca.code_country) desc_country_address,
                ca.alpha2_code code_country_address,
                psa.id_scholarship qualifications,
                pk_translation.get_translation(1, s.code_scholarship) qualifications_desc,
                occ.id_occupation profession_code,
                pk_translation.get_translation(1, occ.code_occupation) profession_desc,
                psa.flg_job_status profession_practice,
                pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', psa.flg_job_status, 1) profession_practice_desc,
                psa.father_name ,
                psa.mother_name
  FROM p1_external_request exr
  JOIN patient p ON (exr.id_patient = p.id_patient)
  LEFT JOIN pat_health_plan php ON (php.id_patient = exr.id_patient AND php.id_institution IS NULL AND
                                   php.flg_status = 'A' AND
                                   php.id_health_plan =
                                   to_number(pk_sysconfig.get_config('IDENT_ID_HEALTH_PLAN',
                                                                      profissional(NULL, exr.id_inst_dest, NULL))))
  LEFT JOIN contact c ON (p.id_person = c.id_contact_entity)
  LEFT JOIN contact_address_pt ca_pt ON (ca_pt.id_contact_address_pt = c.id_contact)
  LEFT JOIN district d ON (d.id_district = ca_pt.id_district)
  LEFT JOIN pat_soc_attributes psa ON (psa.id_patient = p.id_patient AND psa.id_institution = 0)
  JOIN pat_soc_attributes_pt psa_pt ON (psa_pt.id_pat_soc_attributes_pt = psa.id_pat_soc_attributes)
  LEFT JOIN recm ON (recm.id_recm = psa_pt.id_recm)
  LEFT JOIN isencao i ON (i.id_isencao = psa.id_isencao)
  LEFT JOIN country ca ON (ca.id_country = psa.id_country_address AND ca.flg_available = 'Y')
  LEFT JOIN country cn ON (cn.id_country = psa.id_country_nation  AND cn.flg_available = 'Y')
  LEFT JOIN clin_record cr ON (cr.id_patient = p.id_patient AND cr.id_institution = exr.id_inst_dest AND
                              cr.flg_status = 'A')
  LEFT JOIN p1_match m ON (p.id_patient = m.id_patient AND m.id_institution = exr.id_inst_dest AND m.flg_status = 'A')
  LEFT JOIN pat_job pj ON (p.id_patient = pj.id_patient)
  LEFT JOIN occupation occ ON (pj.id_occupation = occ.id_occupation)
  LEFT JOIN scholarship s ON (psa.id_scholarship = s.id_scholarship);

COMMENT ON TABLE V_REFERRAL_PAT IS 'Information of patients who have referrals'
/

COMMENT ON COLUMN V_REFERRAL_PAT.ID_PATIENT IS 'Patient identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT.N_SNS IS 'Patient sns number'
/

COMMENT ON COLUMN V_REFERRAL_PAT.SEQUENTIAL_NUMBER IS 'Clinical process number within the institution'
/

COMMENT ON COLUMN V_REFERRAL_PAT.NUM_CLIN_RECORD IS 'Clinical process number within the institution'
/

COMMENT ON COLUMN V_REFERRAL_PAT.ID_INST_ORIG IS 'Referral origin institution identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT.ID_INST_DEST IS 'Referral destination institution identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT.NAME IS 'Patient name'
/

COMMENT ON COLUMN V_REFERRAL_PAT.GENDER IS 'Patient gender'
/

COMMENT ON COLUMN V_REFERRAL_PAT.GENDER_DESC IS 'Patient gender description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.DT_BIRTH IS 'Patient birth date'
/

COMMENT ON COLUMN V_REFERRAL_PAT.MARITAL_STATUS IS 'Patient marital status'
/

COMMENT ON COLUMN V_REFERRAL_PAT.DESC_MARITAL_STATUS IS 'Patient marital status description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.EXEMPTION_TYPE IS 'Exemption type identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT.EXEMPTION_TYPE_DESC IS 'Exemption type description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.ID_RECM IS 'RECM identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT.DESC_RECM IS 'RECM description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.NICS IS 'NICS'
/

COMMENT ON COLUMN V_REFERRAL_PAT.PHONE IS 'Patient main contact'
/

COMMENT ON COLUMN V_REFERRAL_PAT.NUM_CONTACT IS 'Patient contact number'
/

COMMENT ON COLUMN V_REFERRAL_PAT.ADDRESS IS 'Patient address'
/

COMMENT ON COLUMN V_REFERRAL_PAT.POSTAL_CODE IS 'Patient zip code'
/

COMMENT ON COLUMN V_REFERRAL_PAT.LOCALITY IS 'Patient locality'
/

COMMENT ON COLUMN V_REFERRAL_PAT.DISTRICT IS 'Patient district'
/

COMMENT ON COLUMN V_REFERRAL_PAT.BIRTH_PLACE IS 'Patient birth place'
/

COMMENT ON COLUMN V_REFERRAL_PAT.DESC_COUNTRY_NATIONALITY IS 'Country nationality description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.CODE_COUNTRY_NATIONALITY IS 'Country nationality code'
/

COMMENT ON COLUMN V_REFERRAL_PAT.DESC_COUNTRY_ADDRESS IS 'Country address description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.CODE_COUNTRY_ADDRESS IS 'Country address code'
/

COMMENT ON COLUMN V_REFERRAL_PAT.QUALIFICATIONS IS 'Patient qualifications identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT.QUALIFICATIONS_DESC IS 'Patient qualifications description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.PROFESSION_CODE IS 'Patient occupation identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT.PROFESSION_DESC IS 'Patient occupation description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.PROFESSION_PRACTICE IS 'Job status: active, retired by disability, retired by old age, unemployed'
/

COMMENT ON COLUMN V_REFERRAL_PAT.PROFESSION_PRACTICE_DESC IS 'Job status description'
/

COMMENT ON COLUMN V_REFERRAL_PAT.FATHER_NAME IS 'Patient father name'
/

COMMENT ON COLUMN V_REFERRAL_PAT.MOTHER_NAME IS 'Patient mother name'
/
