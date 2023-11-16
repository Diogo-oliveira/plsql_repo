-->v_epis_type_soft_inst
create or replace view v_epis_type_soft_inst as
SELECT id_epis_type, id_software, id_institution
  FROM epis_type_soft_inst;
