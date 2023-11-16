-->v_pat_ext_sys
create or replace view v_pat_ext_sys as
SELECT id_patient, VALUE, id_institution, id_external_sys
  FROM pat_ext_sys;
