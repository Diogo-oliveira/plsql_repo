-- CHANGED BY: Gilberto Rocha
-- CHANGED DATE: 2021-05-20
-- CHANGE REASON: EMR-45304

CREATE OR REPLACE VIEW V_PAT_HEALTH_PLAN AS
SELECT php.id_pat_health_plan,
       php.id_patient,
       php.num_health_plan,
       php.flg_status,
       php.flg_default,
       php.desc_health_plan,
       php.dt_health_plan,
       php.id_health_plan,
       php.Id_institution,
       hp.code_health_plan,
       hp.flg_instit_type,
       hp.flg_type,
       hp.flg_client,
       hp.insurance_class,
       hp.id_content,
       hp.id_health_plan_entity,
       php.dt_effective,
       php.flg_migrant,
       php.id_country,
       php.inst_identifier_number,
       php.inst_identifier_desc
  FROM pat_health_plan php
 JOIN health_plan hp
   ON php.id_health_plan = hp.id_health_plan;

-- CHANGED END: Gilberto Rocha