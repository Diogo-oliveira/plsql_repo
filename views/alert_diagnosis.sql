BEGIN
  PK_FRMW_OBJECTS.SET_DT_LEASE('ALERT', 'ALERT_DIAGNOSIS');
END;
/

CREATE OR REPLACE VIEW ALERT_DIAGNOSIS AS
SELECT ct.id_concept_term id_alert_diagnosis,
       ct.id_concept_vers_start id_diagnosis,
       CAST(pk_api_pfh_diagnosis_in.get_diag_term(ct.id_concept_term) AS VARCHAR2(200 CHAR)) code_alert_diagnosis,
       CAST(pk_api_pfh_diagnosis_in.get_diag_term(ct.id_concept_term, 62) AS VARCHAR2(200 CHAR)) code_medical,
       CAST(pk_api_pfh_diagnosis_in.get_diag_term(ct.id_concept_term, 61) AS VARCHAR2(200 CHAR)) code_surgical,
       CAST(pk_api_pfh_diagnosis_in.get_diag_term(ct.id_concept_term, 60) AS VARCHAR2(200 CHAR)) code_problems,
       CAST(pk_api_pfh_diagnosis_in.get_diag_term(ct.id_concept_term, 64) AS VARCHAR2(200 CHAR)) code_cong_anomalies,
       CAST(pk_api_pfh_diagnosis_in.get_alert_diag_flg_type(ct.id_concept_term) AS VARCHAR2(2 CHAR)) flg_type,
       CAST(pk_api_pfh_diagnosis_in.get_alert_diag_flg_icd9(ct.id_concept_term) AS VARCHAR2(2 CHAR)) flg_icd9,
       ct.flg_available,
       SYSDATE adw_last_update,
       CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) gender,
       -999 age_min, -- DEPRECATED
       999 age_max, -- DEPRECATED
       CAST(('TMP.TSCT.' || ct.id_concept_term) AS VARCHAR2(200 CHAR)) id_content,
       CAST(pk_api_pfh_diagnosis_in.get_concept_id_language(ct.id_concept_vers_start) AS NUMBER(24)) id_language
  FROM concept_term ct;
