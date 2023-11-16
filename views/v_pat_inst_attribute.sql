-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2014-08-19
-- CHANGE REASON: ADT-8404

CREATE OR REPLACE VIEW V_PAT_INST_ATTRIBUTE AS
SELECT cr.id_patient,
           cr.id_institution,
           cr.id_instit_enroled,
           cr.id_pat_family,
           cr.num_clin_record,
           cr.flg_status clin_record_flg_status,
           pca.flg_pregnancy,
           pca.flg_breast_feed,
           (SELECT de.num_doc
              FROM doc_external de
             WHERE de.flg_status = 'A'
               AND de.id_doc_type = pk_sysconfig.get_config('DOC_TYPE_PATIENT_ID', cr.id_institution, NULL)) num_doc_type_patient,
           psa.marital_status,
           psa.address,
           psa.location,
           psa.district,
           psa.zip_code,
           psa.id_country_address,
           psa.id_country_nation,
           psa.num_main_contact,
           psa.num_contact,
           psa.flg_job_status,
           psa.father_name,
           psa.mother_name,
           id_scholarship,
           id_religion,
           (SELECT c.code_country
              FROM country c
             WHERE c.id_country = psa.id_country_nation) country_nation_code_country,
           (SELECT c.alpha2_code
              FROM country c
             WHERE c.id_country = psa.id_country_nation) country_nation_alpha2_code,
           reason_type care_inst_reason_type,
           reason care_inst_reason,
           pci.dt_begin_tstz care_inst_dt_begin_tstz,
           psa.num_contrib,
           psa.document_identifier_number,
           psa.doc_ident_validation_date,
           psa.doc_ident_identification_date,
           psa.id_doc_type,
           psa.id_language,
           psa.id_institution id_original_institution,
           psa.flg_sns_unknown_reason,
           psa.legal_guardian,
           pf.num_family_record,
		   psa.flg_nhn_status,
           psa.flg_migrator,
           psa.notes,
           pi.old_process_number
      FROM clin_record cr
      LEFT JOIN pat_cli_attributes pca ON cr.id_patient = pca.id_patient
                                      AND cr.id_institution = pca.id_institution
      LEFT JOIN pat_soc_attributes psa ON cr.id_patient = psa.id_patient
                                      AND cr.id_institution = psa.id_institution
      LEFT JOIN patient_care_inst pci ON cr.id_patient = pci.id_patient
                                     AND cr.id_institution = pci.id_institution
                                     AND cr.id_instit_enroled = pci.id_institution_enroled
      LEFT JOIN pat_family pf ON pf.id_pat_family = cr.id_pat_family
      JOIN v_pat_identifier pi
        ON pi.id_clin_record = cr.id_clin_record;

-- CHANGED END: Bruno Martins

-- CHANGED BY: Nuno Amorim
-- CHANGED DATE: 2020-06-03
-- CHANGE REASON: EMR-32646

CREATE OR REPLACE VIEW V_PAT_INST_ATTRIBUTE AS
SELECT cr.id_patient,
           cr.id_institution,
           cr.id_instit_enroled,
           cr.id_pat_family,
           cr.num_clin_record,
           cr.flg_status clin_record_flg_status,
           pca.flg_pregnancy,
           pca.flg_breast_feed,
           (SELECT de.num_doc
              FROM doc_external de
             WHERE de.flg_status = 'A'
               AND de.id_doc_type = pk_sysconfig.get_config('DOC_TYPE_PATIENT_ID', cr.id_institution, NULL)) num_doc_type_patient,
           psa.marital_status,
           psa.address,
           psa.location,
           psa.district,
           psa.zip_code,
           psa.id_country_address,
           psa.id_country_nation,
           psa.num_main_contact,
           psa.num_contact,
           psa.flg_job_status,
           psa.father_name,
           psa.mother_name,
           id_scholarship,
           id_religion,
           (SELECT c.code_country
              FROM country c
             WHERE c.id_country = psa.id_country_nation) country_nation_code_country,
           (SELECT c.alpha2_code
              FROM country c
             WHERE c.id_country = psa.id_country_nation) country_nation_alpha2_code,
           reason_type care_inst_reason_type,
           reason care_inst_reason,
           pci.dt_begin_tstz care_inst_dt_begin_tstz,
           psa.num_contrib,
           psa.document_identifier_number,
           psa.doc_ident_validation_date,
           psa.doc_ident_identification_date,
           psa.id_doc_type,
           psa.id_language,
           psa.id_institution id_original_institution,
           psa.flg_sns_unknown_reason,
           psa.legal_guardian,
           pf.num_family_record,
		   psa.flg_nhn_status,
           psa.flg_migrator,
           psa.notes,
           pi.old_process_number
      FROM clin_record cr
      LEFT JOIN pat_cli_attributes pca ON cr.id_patient = pca.id_patient
                                      AND cr.id_institution = pca.id_institution
      LEFT JOIN pat_soc_attributes psa ON cr.id_patient = psa.id_patient
                                      AND cr.id_instit_enroled = psa.id_institution
      LEFT JOIN patient_care_inst pci ON cr.id_patient = pci.id_patient
                                     AND cr.id_institution = pci.id_institution
                                     AND cr.id_instit_enroled = pci.id_institution_enroled
      LEFT JOIN pat_family pf ON pf.id_pat_family = cr.id_pat_family
      JOIN v_pat_identifier pi
        ON pi.id_clin_record = cr.id_clin_record;

-- CHANGED END: Nuno Amorim