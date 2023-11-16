CREATE OR REPLACE VIEW V_EPIS_DIAG_STAG_TNM AS
WITH tbl_aux AS
 (SELECT ad.id_alert_diagnosis id_concept_term, d.code_icd
    FROM diagnosis d
    JOIN alert_diagnosis ad
      ON ad.id_diagnosis = d.id_diagnosis)
SELECT a.id_epis_diagnosis,
       a.code_tnm_t,
       a.concept_code_tnm_t,
       a.code_tnm_t || a.concept_code_tnm_t code_t,
       a.code_tnm_n,
       a.concept_code_tnm_n,
       a.code_tnm_n || a.concept_code_tnm_n code_n,
       a.code_tnm_m,
       a.concept_code_tnm_m,
       a.code_tnm_m || a.concept_code_tnm_m code_m
  FROM (SELECT e.id_epis_diagnosis,
               (SELECT t.code_icd
                  FROM tbl_aux t
                 WHERE t.id_concept_term = e.id_tnm_t) concept_code_tnm_t,
               e.code_tnm_t,
               (SELECT t.code_icd
                  FROM tbl_aux t
                 WHERE t.id_concept_term = e.id_tnm_n) concept_code_tnm_n,
               e.code_tnm_n,
               (SELECT t.code_icd
                  FROM tbl_aux t
                 WHERE t.id_concept_term = e.id_tnm_m) concept_code_tnm_m,
               e.code_tnm_m
          FROM epis_diag_stag e) a;
