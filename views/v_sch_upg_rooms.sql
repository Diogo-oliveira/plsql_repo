-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW v_sch_upg_rooms as
	SELECT s.id_schedule, s.dt_begin_tstz, s.dt_end_tstz, s.id_dcs_requested, d.id_institution, s.id_room, s.id_schedule c_id_schedule,
			NVL(s.dt_end_tstz,
				NVL((select NVL(dt_end_tstz, s.dt_begin_tstz + interval '30' minute) from sch_consult_vacancy where id_sch_consult_vacancy = s.id_sch_consult_vacancy),
					(s.dt_begin_tstz + interval '30' minute))) best_dt_end
	FROM alert.schedule s
    JOIN alert.dep_clin_serv dcs ON s.id_dcs_requested = dcs.id_dep_clin_serv
    JOIN alert.department d ON dcs.id_department = d.id_department
	WHERE s.flg_status IN ('A', 'T')
		AND s.id_schedule <> -1
		AND s.flg_sch_type <> 'PM'
    AND s.id_room IS NOT NULL
	UNION
  SELECT s1.id_schedule, s1.dt_begin_tstz, s1.dt_end_tstz, s1.id_dcs_requested, d.id_institution, s1.id_room, s1.id_schedule c_id_schedule,
          NVL(s1.dt_end_tstz,
              NVL((select NVL(dt_end_tstz, s1.dt_begin_tstz + interval '30' minute) from sch_consult_vacancy where id_sch_consult_vacancy = s1.id_sch_consult_vacancy),
                  (s1.dt_begin_tstz + interval '30' minute))) best_dt_end
  FROM alert.schedule s1
    LEFT JOIN alert.schedule s2 ON s1.id_Schedule = s2.id_schedule_ref
    JOIN alert.dep_clin_serv dcs ON s1.id_dcs_requested = dcs.id_dep_clin_serv
    JOIN alert.department d ON dcs.id_department = d.id_department
  WHERE s1.flg_status = 'C'
    AND s1.id_schedule <> -1
    AND s1.id_schedule_ref is null
    AND s2.id_schedule_ref is null
    AND s1.flg_sch_type <> 'PM'
    AND s1.id_room IS NOT NULL;
-- CHANGE END: Telmo
