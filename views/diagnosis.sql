BEGIN
  PK_FRMW_OBJECTS.SET_DT_LEASE('ALERT', 'DIAGNOSIS');
END;
/

CREATE OR REPLACE VIEW DIAGNOSIS AS
SELECT diag.id_diagnosis,
       diag.id_diagnosis_parent,
       diag.code_diagnosis,
       diag.code_icd,
       diag.flg_select,
       diag.flg_job,
       diag.flg_available,
       diag.adw_last_update,
       diag.flg_type,
       diag.flg_other,
       diag.gender,
       diag.age_min,
       diag.age_max,
       diag.mdm_coding,
       diag.flg_family,
       diag.flg_pos_birth,
       diag.flg_subtype,
       diag.id_content,
       diag.concept_type_int_name,
       diag.id_concept,
       diag.id_terminology_version,
       (SELECT dc.id_codification
          FROM diag_codification dc
         WHERE dc.flg_diag_type = diag.flg_type) id_codification,
       diag.term_international_code
  FROM (SELECT cver.id_concept_version id_diagnosis,
               CAST(pk_api_pfh_diagnosis_in.get_diagnosis_parent(cver.id_concept, cver.id_terminology_version) AS
                    NUMBER(24)) id_diagnosis_parent,
               CAST(pk_api_pfh_diagnosis_in.get_diag_preferred_term(cver.id_concept_version) AS VARCHAR2(200 CHAR)) code_diagnosis,
               c.code code_icd,
               CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) flg_select,
               CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) flg_job,
               'Y' flg_available,
               SYSDATE adw_last_update,
               CAST(pk_api_pfh_diagnosis_in.get_diag_flg_type(tv.id_terminology) AS VARCHAR2(200 CHAR)) flg_type,
               CAST(pk_api_pfh_diagnosis_in.get_diag_flg_other(tv.id_terminology, cver.id_concept) AS VARCHAR2(1 CHAR)) flg_other,
               CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) gender,
               -999 age_min, -- DEPRECATED
               999 age_max, -- DEPRECATED
               999999999999 mdm_coding, -- DEPRECATED
               CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) flg_family,
               CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) flg_pos_birth,
               CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) flg_subtype,
               CAST(('TMP.TSC.' || cver.id_concept_version) AS VARCHAR2(200 CHAR)) id_content,
               CAST(pk_api_pfh_diagnosis_in.get_diag_int_name(tv.id_terminology, cver.id_concept) AS VARCHAR2(200 CHAR)) concept_type_int_name,
               cver.id_concept,
               cver.id_terminology_version,
               tv.id_language,
               t.hl7_oid term_international_code
          FROM concept_version cver
          JOIN concept c
            ON c.id_concept = cver.id_concept
          JOIN terminology_version tv
            ON tv.id_terminology_version = cver.id_terminology_version
          JOIN terminology t
            ON t.id_terminology = tv.id_terminology) diag;
