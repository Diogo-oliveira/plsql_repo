CREATE OR REPLACE VIEW V_REFERRAL_PAT_DOC AS
SELECT DISTINCT de.id_patient id_patient,
                dt.id_doc_type id_doc_type,
                pk_translation.get_translation(1, dt.code_doc_type) desc_doc_type,
                de.num_doc num_doc
  FROM doc_external de
  JOIN doc_type dt ON (de.id_doc_type = dt.id_doc_type)
  JOIN p1_external_request p ON (p.id_patient = de.id_patient)
  where de.flg_status = 'A';
	
COMMENT ON TABLE V_REFERRAL_PAT_DOC IS 'Referral patient documents'
/

COMMENT ON COLUMN V_REFERRAL_PAT_DOC.ID_PATIENT IS 'Patient identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT_DOC.ID_DOC_TYPE IS 'Patient document type identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT_DOC.DESC_DOC_TYPE IS 'Patient document type description'
/

COMMENT ON COLUMN V_REFERRAL_PAT_DOC.NUM_DOC IS 'Document number'
/
