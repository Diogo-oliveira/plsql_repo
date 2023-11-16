CREATE OR REPLACE VIEW V_CLIN_SERV_PROBLEMS AS
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
       t.flg_type,
       t.flg_mechanism,
       t.id_tvr_msi
FROM TABLE(pk_terminology_search.tf_get_clin_serv_problems) t;