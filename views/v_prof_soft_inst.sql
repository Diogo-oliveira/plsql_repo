-->V_PROF_SOFT_INST
CREATE OR REPLACE VIEW V_PROF_SOFT_INST AS
SELECT psi.id_prof_soft_inst, psi.id_professional, psi.id_software, psi.id_institution, psi.dt_log_tstz
  FROM PROF_SOFT_INST psi;
