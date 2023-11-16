CREATE OR REPLACE VIEW ALERT_DIAGNOSIS_TYPE AS
SELECT ct.id_concept_term id_alert_diagnosis,
       ct.id_concept_vers_start id_diagnosis,
       CAST(pk_api_pfh_diagnosis_in.get_diag_term(ct.id_concept_term, ctt.id_task_type) AS VARCHAR2(200 CHAR)) code_translation,
       CAST(pk_api_pfh_diagnosis_in.get_alert_diag_flg_type(ct.id_concept_term, ctt.id_task_type) AS VARCHAR2(2 CHAR)) flg_type,
       CAST(pk_api_pfh_diagnosis_in.get_alert_diag_flg_icd9(ct.id_concept_term) AS VARCHAR2(2 CHAR)) flg_icd9,
       ct.flg_available,
       SYSDATE adw_last_update,
       CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) gender,
       -999 age_min, -- DEPRECATED
       999 age_max, -- DEPRECATED
       CAST(('TMP.TSCT.' || ct.id_concept_term) AS VARCHAR2(200 CHAR)) id_content,
       CAST(pk_api_pfh_diagnosis_in.get_concept_id_language(ct.id_concept_vers_start) AS NUMBER(24)) id_language,
       ctt.id_task_type
  FROM concept_term ct
  JOIN concept_term_task_type ctt
    ON ctt.id_concept_term = ct.id_concept_term
 WHERE ctt.id_task_type = sys_context('ALERT_CONTEXT', 'TERM_TASK_TYPE')
    OR sys_context('ALERT_CONTEXT', 'TERM_TASK_TYPE') IS NULL;