create or replace view search_alert_diagnosis
select null id_alert_diagnosis,
       null id_diagnosis,
       null code_alert_diagnosis,
       null code_medical,
       null code_surgical,
       null code_problems,
       null code_cong_anomalies,
       null flg_type,
       null flg_icd9,
       null flg_available,
       null adw_last_update,
       null gender,
       null age_min,
       null age_max,
       null id_content,
       null id_language
  from dual;