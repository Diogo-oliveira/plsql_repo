CREATE OR REPLACE VIEW V_SCH_DEP_CLIN_SERV AS
SELECT s.id_institution,
       dcs.id_dep_clin_serv,
       dcs.id_department,
       dcs.id_clinical_service,
       decode(dcs.flg_available, 'Y', 'A', 'I') flg_available
  FROM dep_clin_serv dcs
  JOIN department s
    ON dcs.id_department = s.id_department;