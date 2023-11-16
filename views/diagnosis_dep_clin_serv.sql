--Ignora temporáriamente as regras dos FRMW_OBJECTS
BEGIN
    pk_frmw_objects.set_dt_lease('ALERT', 'DIAGNOSIS_DEP_CLIN_SERV');

    EXECUTE IMMEDIATE '
CREATE OR REPLACE VIEW DIAGNOSIS_DEP_CLIN_SERV AS
SELECT CAST(-1 AS NUMBER(24)) id_diagnosis_dep_clin_serv, -- DEPRECATED
       CAST(decode(d.id_dep_clin_serv, -1, NULL, d.id_dep_clin_serv) AS NUMBER(24)) id_dep_clin_serv,
       d.id_concept_version id_diagnosis,
       d.rank,
       SYSDATE adw_last_update,
       d.flg_msi_concept_term flg_type,
       CAST(decode(d.id_institution, -1, NULL, d.id_institution) AS NUMBER(24)) id_institution,
       d.id_software,
       CAST(decode(d.id_professional, -1, NULL, d.id_professional) AS NUMBER(24)) id_professional,
       d.id_concept_term id_alert_diagnosis,
       0 id_diag_inst_owner,
       0 id_adiag_inst_owner
  FROM diagnosis_ea d
 WHERE d.flg_is_diagnosis = ''Y''';
END;
/
