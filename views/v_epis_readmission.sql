-->V_EPIS_READMISSION
CREATE OR REPLACE VIEW V_EPIS_READMISSION AS
SELECT id_epis_readmission, id_episode, id_professional, dt_begin_tstz, dt_end_tstz
  FROM epis_readmission;
