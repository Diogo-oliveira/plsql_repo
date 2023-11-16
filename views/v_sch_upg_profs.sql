-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
create or replace view v_sch_upg_profs as
select s.id_schedule, s.dt_begin_tstz, s.dt_end_tstz, s.id_dcs_requested, sr.id_sch_resource, sr.id_professional, sr.flg_leader, sr.id_institution, s.id_schedule c_id_schedule,
NVL(s.dt_end_tstz,
            NVL((select NVL(dt_end_tstz, s.dt_begin_tstz + interval '30' minute) from sch_consult_vacancy where id_sch_consult_vacancy = s.id_sch_consult_vacancy),
                (s.dt_begin_tstz + interval '30' minute))) best_dt_end
  FROM alert.schedule s
 JOIN alert.sch_resource sr ON s.id_schedule = sr.id_schedule
 WHERE s.flg_status IN ('A', 'T')
    AND s.id_schedule <> -1
  AND s.flg_sch_type <> 'PM'
  UNION
select s1.id_schedule, s1.dt_begin_tstz, s1.dt_end_tstz, s1.id_dcs_requested, sr.id_sch_resource, sr.id_professional, sr.flg_leader, sr.id_institution, s1.id_schedule c_id_schedule,
NVL(s1.dt_end_tstz,
            NVL((select NVL(dt_end_tstz, s1.dt_begin_tstz + interval '30' minute) from sch_consult_vacancy where id_sch_consult_vacancy = s1.id_sch_consult_vacancy),
                (s1.dt_begin_tstz + interval '30' minute))) best_dt_end
  FROM alert.schedule s1
  LEFT JOIN alert.schedule s2 ON s1.id_Schedule = s2.id_schedule_ref
 JOIN alert.sch_resource sr ON s1.id_schedule = sr.id_schedule
  WHERE s1.flg_status = 'C'
    AND s1.id_schedule <> -1
    and s1.id_schedule_ref is null
    and s2.id_schedule_ref is null
  AND s1.flg_sch_type <> 'PM';
-- CHANGE END: Telmo
