CREATE OR REPLACE VIEW V_COMPLICATIONS_PAT_FINAL AS
SELECT id_language, id_diagnosis, desc_diagnosis, id_alert_diagnosis, code_diagnosis, code_icd, views_rank
  FROM (SELECT t.*, row_number() over(PARTITION BY id_diagnosis, id_alert_diagnosis ORDER BY id_language NULLS FIRST) rn
          FROM (SELECT NULL id_language, id_diagnosis, desc_diagnosis, id_alert_diagnosis, code_diagnosis, code_icd, views_rank
                  FROM (SELECT t.*
                          FROM v_complications t
                         WHERE 1 = 1) t
                UNION ALL
                SELECT t.id_language, id_diagnosis, desc_diagnosis, id_alert_diagnosis, code_diagnosis, code_icd, views_rank
                  FROM (SELECT t.*
                          FROM v_patient_diagnoses_final t
                         WHERE 1 = 1
                        UNION
                        SELECT t.*
                          FROM v_patient_diagnoses_diff t
                         WHERE 1 = 1
                        UNION
                        SELECT t.*
                          FROM v_patient_hist_prob t
                         WHERE 1 = 1) t) t)
 WHERE rn > 1;