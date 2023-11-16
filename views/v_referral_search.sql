-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2012-MAY-09
-- CHANGED REASON: ALERT-229580
CREATE OR REPLACE VIEW V_REFERRAL_SEARCH AS
SELECT p1.id_external_request,
       p1.id_patient,
       p1.id_inst_dest,
       p1.id_speciality,
       p1.flg_status,
       php.num_health_plan    n_sns,
       NULL                   sequential_number,
       cr.num_clin_record,
       p1.dt_status_tstz
  FROM p1_external_request p1
  JOIN patient p
    ON (p.id_patient = p1.id_patient)
  LEFT JOIN pat_health_plan php
    ON (php.id_patient = p1.id_patient AND php.id_institution IS NULL AND php.flg_status = 'A' AND
       php.id_health_plan = to_number(sys_context('ALERT_CONTEXT', 'IDENT_ID_HEALTH_PLAN')))
  LEFT JOIN clin_record cr
    ON (cr.id_patient = p.id_patient AND cr.id_institution = p1.id_inst_dest AND cr.flg_status = 'A'); 