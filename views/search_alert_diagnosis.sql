CREATE OR REPLACE VIEW SEARCH_ALERT_DIAGNOSIS AS

/*SELECT id_alert_diagnosis,
       id_diagnosis,
       code_alert_diagnosis,
       code_alert_diagnosis code_medical,
       code_alert_diagnosis code_surgical,
       code_alert_diagnosis code_problems,
       code_alert_diagnosis code_cong_anomalies,
       flg_type,
       flg_icd9,
       flg_available,
       adw_last_update,
       gender,
       age_min,
       age_max,
       id_content,
       create_user,
       create_time,
       create_institution,
       update_user,
       update_time,
       update_institution,
       null id_language
  FROM mig_alert_diagnosis;*/

SELECT DISTINCT d.id_concept_term id_alert_diagnosis,
                d.id_concept_version id_diagnosis,
                d.code_diagnosis code_alert_diagnosis,
                d.code_medical,
                d.code_surgical,
                d.code_problems,
                d.code_cong_anomalies,
                d.flg_diag_type flg_type,
                d.flg_icd9,
                'Y' flg_available,
                SYSDATE adw_last_update,
                d.gender,
                d.age_min,
                d.age_max,
                'DEPRECATED' id_content,
                d.id_language
  FROM diagnosis_ea d
 WHERE d.concept_type_int_name IN ('DIAGNOSIS', 'CANCER_DIAGNOSIS');



DROP VIEW search_alert_diagnosis;



