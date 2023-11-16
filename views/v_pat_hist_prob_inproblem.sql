CREATE OR REPLACE VIEW v_pat_hist_prob_inproblem AS
SELECT t.id_diagnosis,
       t.id_alert_diagnosis,
       t.code_icd,
       t.id_language,
       t.code_diagnosis code_translation,
       t.desc_diagnosis desc_translation,
       t.desc_epis_diagnosis,
       t.flg_other,
       t.flg_icd9,
       NULL flg_select,
       t.rank,
       t.flg_show_term_code,
       t.flg_status,
       t.flg_type
  FROM TABLE(pk_terminology_search.tf_patient_hist_prob) t
  WHERE (t.id_diagnosis, t.desc_diagnosis) NOT IN
       (SELECT ted.id_diagnosis, ted.desc_translation
          FROM TABLE(pk_terminology_search.tf_episode_diagnoses) ted
        UNION ALL
        SELECT pdf.id_diagnosis, pdf.desc_diagnosis
          FROM TABLE(pk_terminology_search.tf_patient_diagnoses_diff) pdf
        UNION ALL
        SELECT pdfi.id_diagnosis, pdfi.desc_diagnosis
          FROM TABLE(pk_terminology_search.tf_patient_diagnoses_final) pdfi)