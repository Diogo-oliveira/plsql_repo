CREATE OR REPLACE VIEW V_SCH_CLINICAL_SERVICE AS
SELECT cs.id_clinical_service,
       cs.id_content id_content_clin_serv,
       cs.code_clinical_service code_translation,
       decode(cs.flg_available, 'Y', 'A', 'I') flg_available
  FROM clinical_service cs;