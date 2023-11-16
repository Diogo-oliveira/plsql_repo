CREATE OR REPLACE VIEW V_SCH_REHAB_GROUPS AS
SELECT rg.id_institution, rg.id_rehab_group id_group, rg.name, rg.description, decode(rg.flg_status, 'Y', 'A', 'I')  flg_available
  FROM rehab_group rg;