CREATE OR REPLACE VIEW SEARCH_DIAGNOSIS AS

/*SELECT id_diagnosis,
       id_diagnosis_parent,
       code_diagnosis,
       code_icd,
       flg_select,
       flg_job,
       flg_available,
       adw_last_update,
       flg_type,
       flg_other,
       gender,
       age_min,
       age_max,
       mdm_coding,
       flg_family,
       flg_pos_birth,
       flg_subtype,
       id_content,
       create_user,
       create_time,
       create_institution,
       update_user,
       update_time,
       update_institution,
       'CANCER_DIAGNOSIS_TEMP' concept_type_int_name, -- same as DIAGNOSIS_EA.CONCEPT_TYPE_INT_NAME
       null code_diagnosis_task,
       null code_medical,
       null code_surgical,
       null code_problems,
       null code_cong_anomalies
  FROM mig_diagnosis t;*/

SELECT DISTINCT d.id_concept_version id_diagnosis,
                CAST(pk_diagnosis.get_diagnosis_parent(d.id_concept_version, d.id_institution, d.id_software) AS NUMBER(24)) id_diagnosis_parent,
                'DEPRECATED' code_diagnosis,
                d.concept_code code_icd,
                d.flg_select,
                d.flg_job,
                'Y' flg_available,
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
                'DEPRECATED' id_content,
                d.concept_type_int_name
  FROM diagnosis_ea d
 WHERE d.concept_type_int_name IN ('DIAGNOSIS', 'CANCER_DIAGNOSIS');



DROP VIEW search_diagnosis;


