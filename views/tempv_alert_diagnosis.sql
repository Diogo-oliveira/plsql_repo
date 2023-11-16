create or replace view alert_diagnosis
select id_alert_diagnosis,
       id_diagnosis,
       code_alert_diagnosis,
       null code_medical,
       null code_surgical,
       null code_problems,
       null code_cong_anomalies,
       flg_type,
       flg_icd9,
       flg_available,
       adw_last_update,
       gender,
       age_min,
       age_max,
       null id_content,
       null id_language
  from mig_alert_diagnosis;