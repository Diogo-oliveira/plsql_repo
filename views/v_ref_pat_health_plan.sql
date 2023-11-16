-- CHANGED BY: João Almeida
-- CHANGED DATE: 2009-SEP-29
-- CHANGED REASON: ALERT-46872
CREATE OR REPLACE VIEW V_REF_PAT_HEALTH_PLAN AS
SELECT DISTINCT exr.id_patient,
                php.num_health_plan,
                php.id_health_plan,
                pk_translation.get_translation(1, hp.code_health_plan) desc_health_plan
  FROM p1_external_request exr
  LEFT JOIN pat_health_plan php ON (php.id_patient = exr.id_patient AND php.id_institution IS NULL AND
                                   php.flg_status = 'A')
  JOIN health_plan hp ON (hp.id_health_plan = php.id_health_plan AND hp.flg_available = 'Y');
-- CHANGE END: João Almeida
