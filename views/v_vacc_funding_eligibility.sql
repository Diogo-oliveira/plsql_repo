create or replace view V_VACC_FUNDING_ELIGIBILITY  AS
SELECT id_vacc_funding_elig id_vacc_funding_eligibility, concept_code ID_CONCEPT_CODE, concept_description, id_content, flg_available
  FROM vacc_funding_eligibility;