-->v_epis_ext_sys
create or replace view v_epis_ext_sys as
SELECT id_episode, VALUE, id_institution, cod_epis_type_ext, id_epis_type, id_external_sys
  FROM epis_ext_sys;
