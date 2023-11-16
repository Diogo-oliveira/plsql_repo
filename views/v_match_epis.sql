CREATE OR REPLACE VIEW v_match_epis AS
SELECT id_match_epis, id_episode, id_episode_temp, id_patient, id_patient_temp, id_professional, dt_match_tstz
  FROM match_epis;
