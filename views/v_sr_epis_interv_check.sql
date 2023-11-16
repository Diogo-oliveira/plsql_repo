CREATE OR REPLACE VIEW V_SR_EPIS_INTERV_CHECK AS
SELECT epi.id_patient,
       epi.id_episode,
       s.id_sr_epis_interv,
       std.dt_surgery_time_det_tstz,
       epi.dt_begin_tstz,
       s.id_sr_intervention,
       epi.id_institution
  FROM v_sr_epis_interv s
  JOIN episode epi
    ON epi.id_episode = s.id_episode_context
  LEFT JOIN sr_surgery_time_det std
    ON std.id_episode = s.id_episode
   AND std.id_sr_surgery_time = 3;

