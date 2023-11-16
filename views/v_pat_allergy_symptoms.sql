-->V_PAT_ALLERGY_SYMPTOMS
CREATE OR REPLACE VIEW ALERT.V_PAT_ALLERGY_SYMPTOMS AS
SELECT pa.id_pat_allergy, a.id_allergy_symptoms, a.id_content AS ID_CONTENT_SYMPTOMS, a.code_allergy_symptoms
  FROM pat_allergy_symptoms pa
  JOIN allergy_symptoms a
    ON a.id_allergy_symptoms = pa.id_allergy_symptoms
    JOIN pat_allergy pat on pat.id_pat_allergy = pa.id_pat_allergy;
