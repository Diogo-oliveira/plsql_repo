-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2012-JUL-23
-- CHANGED REASON: ALERT-237078
CREATE OR REPLACE VIEW V_REF_DEP_CLIN_SERV AS
SELECT id_dep_clin_serv, id_institution, gender, age_min, age_max, id_external_sys
  FROM v_ref_internal;
-- CHANGE END: Ana Monteiro
