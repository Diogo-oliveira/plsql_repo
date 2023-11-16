create or replace view V_VACC_FUNDING_SOURCE  AS
SELECT id_vacc_funding_source, concept_code id_concept_code, concept_description, id_content, flg_available
  FROM vacc_funding_source;
