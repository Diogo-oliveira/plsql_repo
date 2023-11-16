CREATE OR REPLACE VIEW V_INSTIT_EXT_SYS AS
SELECT id_instit_ext_sys, id_external_sys, id_institution, VALUE, id_epis_type, id_clinical_service
  FROM instit_ext_sys;
