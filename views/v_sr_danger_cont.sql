CREATE OR REPLACE VIEW v_sr_danger_cont AS
SELECT id_sr_danger_cont, id_episode, id_patient, id_schedule_sr, id_prof_reg, dt_reg, flg_status, id_epis_diagnosis
  FROM sr_danger_cont
