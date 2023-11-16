CREATE OR REPLACE VIEW v_past_medical_all_content AS
SELECT t.id_diagnosis,
       t.id_alert_diagnosis,
       t.code_icd,
       t.id_language,
       t.code_translation,
       t.desc_translation,
       t.desc_epis_diagnosis,
       t.flg_other,
       t.flg_icd9,
       t.flg_select,
       t.rank,
       t.flg_show_term_code,
       t.flg_status,
       t.flg_type
  FROM TABLE(pk_terminology_search.tf_all_content(i_task_type => 62 /*pk_alert_constant.g_task_medical_history*/)) t;
