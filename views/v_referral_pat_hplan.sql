CREATE OR REPLACE VIEW V_REFERRAL_PAT_HPLAN AS
SELECT DISTINCT exr.id_patient id_patient,
                    php.num_health_plan num_health_plan,
                    php.dt_health_plan dt_health_plan,
                    php.id_health_plan id_health_plan,
                    pk_translation.get_translation(1, hp.code_health_plan) desc_health_plan
      FROM p1_external_request exr
      LEFT JOIN pat_health_plan php ON (php.id_patient = exr.id_patient AND php.id_institution IS NULL AND
      -- id_instituion is NULL because the referrals need to be visible across instituions
                                       php.flg_status = 'A') -- 'A' healthplan is available
      JOIN health_plan hp ON (hp.id_health_plan = php.id_health_plan AND hp.flg_available = 'Y');
			
COMMENT ON TABLE V_REFERRAL_PAT_HPLAN IS 'Referral patients health plan'
/

COMMENT ON COLUMN V_REFERRAL_PAT_HPLAN.ID_PATIENT IS 'Patient identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT_HPLAN.NUM_HEALTH_PLAN IS 'Patient health plan number'
/

COMMENT ON COLUMN V_REFERRAL_PAT_HPLAN.DT_HEALTH_PLAN IS 'Patient health plan expire date'
/

COMMENT ON COLUMN V_REFERRAL_PAT_HPLAN.ID_HEALTH_PLAN IS 'Patient health plan identifier'
/

COMMENT ON COLUMN V_REFERRAL_PAT_HPLAN.DESC_HEALTH_PLAN IS 'Patient health plan description'
/
