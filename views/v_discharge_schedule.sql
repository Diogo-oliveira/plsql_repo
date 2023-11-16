-->V_DISCHARGE_SCHEDULE
CREATE OR REPLACE VIEW V_DISCHARGE_SCHEDULE AS
SELECT id_discharge_schedule,
       id_episode,
       dt_discharge_schedule,
			 flg_status,
			 id_patient,
       flg_hour_origin
  FROM discharge_schedule;
