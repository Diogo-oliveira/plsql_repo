CREATE OR REPLACE VIEW V_PATIENT_HIST_PROB AS
SELECT t.id_diagnosis,
       t.id_diagnosis_parent,
       t.id_epis_diagnosis,
       t.desc_diagnosis,
       t.code_icd,
       t.flg_other,
       t.status_diagnosis,
       t.icon_status,
       t.avail_for_select,
       t.default_new_status,
       t.default_new_status_desc,
       t.id_alert_diagnosis,
       t.desc_epis_diagnosis,
       t.flg_terminology,
       t.flg_diag_type,
       t.code_diagnosis,
       t.flg_icd9,
       t.flg_show_term_code,
       t.id_language,
       t.rank                    content_rank,
       10                        views_rank,
       t.id_tvr_msi
  FROM TABLE(pk_terminology_search.tf_patient_hist_prob) t
 WHERE (t.id_diagnosis, t.desc_diagnosis) NOT IN
       (SELECT pdf.id_diagnosis, pdf.desc_diagnosis
          FROM TABLE(pk_terminology_search.tf_patient_diagnoses_diff) pdf
        UNION ALL
        SELECT pdfi.id_diagnosis, pdfi.desc_diagnosis
          FROM TABLE(pk_terminology_search.tf_patient_diagnoses_final) pdfi);
