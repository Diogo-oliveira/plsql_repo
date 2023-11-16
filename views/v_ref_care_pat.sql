-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2009-OCT-16
-- CHANGED REASON: ALERT-49886
-- correccao: adicionada informacao de distrito, corrigida informacao de country_address
CREATE OR REPLACE VIEW V_REF_CARE_PAT AS
SELECT DISTINCT exr.id_patient patient_id,
                cr.num_clin_record internal_number,
                exr.id_inst_dest id_inst_dest,
                exr.id_inst_orig id_inst_orig,
                p.name name,
                p.gender gender,
                pk_sysdomain.get_domain('PATIENT.GENDER', p.gender, 1) gender_desc,
                p.dt_birth birth_date,
                i.id_isencao exemption_type,
                pk_translation.get_translation(1, i.code_isencao) exemption_type_desc,
                recm.id_recm recm,
                pk_translation.get_translation(1, recm.code_recm) recm_desc,
                psa.num_main_contact phone,
                psa.address address,
                psa.zip_code postal_code,
                psa.location locality,
                --psa.district district,
                pk_translation.get_translation(1, d.code_district) district, -- adicionado
                --pk_translation.get_translation(1, ca.code_country) country,
                --ca.alpha2_code code_country_address,
                (CASE
                     WHEN psa.address IS NOT NULL
                          AND psa.zip_code IS NOT NULL
                          AND psa.location IS NOT NULL THEN
                      pk_translation.get_translation(1, ca.code_country)
                 ELSE
                      NULL
                 END) country, -- adicionado
                (CASE
                     WHEN psa.address IS NOT NULL
                          AND psa.zip_code IS NOT NULL
                          AND psa.location IS NOT NULL THEN
                      ca.alpha2_code
                 ELSE
                      NULL
                 END) code_country_address,                -- adicionado
                psa.marital_status marital_state,
                pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', psa.marital_status, 1) marital_status_desc,
                psa.id_scholarship qualifications,
                pk_translation.get_translation(1, s.code_scholarship) qualifications_desc,
                occ.id_occupation profession_code,
                pk_translation.get_translation(1, occ.code_occupation) profession_desc,
                psa.flg_job_status profession_practice,
                pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', psa.flg_job_status, 1) profession_pratice_desc,
                psa.father_name father,
                psa.mother_name mother
  FROM p1_external_request exr
  JOIN patient p ON (exr.id_patient = p.id_patient)
  LEFT JOIN contact c ON (p.id_person = c.id_contact_entity AND c.id_contact_description = 4) --  adicionado para obter distrito
  LEFT JOIN contact_address_pt ca_pt ON (ca_pt.id_contact_address_pt = c.id_contact) --  adicionado para obter distrito
  LEFT JOIN district d ON (d.id_district = ca_pt.id_district) --  adicionado para obter distrito
  LEFT JOIN pat_soc_attributes psa ON (psa.id_patient = p.id_patient AND psa.id_institution = exr.id_inst_orig)
  JOIN pat_soc_attributes_pt psa_pt ON (psa_pt.id_pat_soc_attributes_pt = psa.id_pat_soc_attributes)
  LEFT JOIN recm ON (recm.id_recm = psa_pt.id_recm)
  LEFT JOIN isencao i ON (i.id_isencao = psa.id_isencao)
  LEFT JOIN country ca ON (ca.id_country = 620 AND ca.flg_available = 'Y') -- correccao: utilizar o valor PT apenas na condicao da coluna
  LEFT JOIN clin_record cr ON (cr.id_patient = p.id_patient AND cr.id_institution = exr.id_inst_dest AND
                              cr.flg_status = 'A')
  LEFT JOIN p1_match m ON (p.id_patient = m.id_patient AND m.id_institution = exr.id_inst_dest AND m.flg_status = 'A')
  LEFT JOIN pat_job pj ON (p.id_patient = pj.id_patient)
  LEFT JOIN occupation occ ON (pj.id_occupation = occ.id_occupation)
  LEFT JOIN scholarship s ON (psa.id_scholarship = s.id_scholarship);
-- CHANGE END: Ana Monteiro