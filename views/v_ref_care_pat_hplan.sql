CREATE OR REPLACE VIEW V_REF_CARE_PAT_HPLAN AS
SELECT DISTINCT exr.id_patient,
                php.num_health_plan,
                --php.dt_health_plan,
                php.id_health_plan,
                pk_translation.get_translation(1, hp.code_health_plan) desc_health_plan
  FROM p1_external_request exr
  LEFT JOIN pat_health_plan php ON (php.id_patient = exr.id_patient AND php.id_institution = exr.id_inst_orig AND
                                   php.flg_status = 'A')
  JOIN health_plan hp ON (hp.id_health_plan = php.id_health_plan AND hp.flg_available = 'Y');