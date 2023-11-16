CREATE OR REPLACE VIEW DIAGNOSIS_CONTENT AS
SELECT d.id_concept_version id_diagnosis,
       CAST((SELECT id_concept_version_2
               FROM diagnosis_relations_ea dr
              WHERE dr.cncpt_rel_type_int_name = 'IS_A'
                AND dr.concept_type_int_name1 = dr.concept_type_int_name2
                AND dr.id_concept_version_1 = d.id_concept_version
                AND dr.id_institution = d.id_institution
                AND dr.id_software = d.id_software) AS NUMBER(24)) id_diagnosis_parent,
       d.concept_code code_icd,
       d.flg_select,
       d.flg_job,
       CAST('Y' AS VARCHAR2(1 CHAR)) flg_available,
       SYSDATE adw_last_update,
       d.flg_terminology flg_type,
       d.flg_other,
       d.gender,
       d.age_min,
       d.age_max,
       d.mdm_coding,
       d.flg_family,
       d.flg_pos_birth,
       d.flg_subtype,
       CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) id_content,
			 0 id_diag_inst_owner,
       d.code_diagnosis code_alert_diagnosis,
       d.code_medical,
       d.code_surgical,
       d.code_problems,
       d.code_cong_anomalies,
       --
       d.rowid rowid_alert_diag,
       d.id_concept_term id_alert_diagnosis,
       d.flg_diag_type flg_type_alert_diagnosis,
       d.flg_icd9,
       CAST('Y' AS VARCHAR2(1 CHAR)) flg_available_alert_diagnosis,
       d.gender gender_alert_diagnosis,
       d.age_min age_min_alert_diagnosis,
       d.age_max age_max_alert_diagnosis,
       CAST('DEPRECATED' AS VARCHAR2(10 CHAR)) id_content_alert_diagnosis,
       d.id_language,
       --
       CAST(decode(d.id_dep_clin_serv, -1, NULL, d.id_dep_clin_serv) AS NUMBER(24)) id_dep_clin_serv,
       d.rank,
       d.flg_msi_concept_term flg_type_dep_clin,
       CAST(decode(d.id_institution, -1, NULL, d.id_institution) AS NUMBER(24)) id_institution,
       CAST(decode(d.id_professional, -1, NULL, d.id_professional) AS NUMBER(24)) id_professional,
       d.id_software,
       d.diagnosis_path,
       d.code_diagnosis_partial,
       (SELECT dc.id_codification
          FROM diag_codification dc
         WHERE dc.flg_diag_type = d.flg_terminology) id_codification
  FROM diagnosis_ea d
 WHERE d.flg_is_diagnosis = 'Y';
