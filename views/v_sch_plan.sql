-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 05-Jul-2010
-- CHANGE REASON: ALERT_109441
create or replace view v_sch_plan as
SELECT sg.id_patient,
       sch.id_schedule,
       sch.id_episode,
       decode(sch.id_sch_event, 17, 5, 1) id_epis_type,
       sch.id_instit_requested id_institution,
       sch.dt_begin_tstz,
       sch.dt_end_tstz
  FROM schedule sch
 INNER JOIN sch_group sg ON (sg.id_schedule = sch.id_schedule)
 WHERE sch.id_sch_event IN (17, 1, 2, 3, 4, 10, 20)
   AND sch.dt_begin_tstz > (current_timestamp - 1);
-- CHANGE END: Rita Lopes

-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 13-Jul-2010
-- CHANGE REASON: ALERT_109441
create or replace view v_sch_plan as
SELECT sg.id_patient,
       sch.id_schedule,
       sch.id_episode,
       decode(sch.id_sch_event, 17, 5, 1) id_epis_type,
       sch.id_instit_requested id_institution,
       sch.dt_begin_tstz,
       sch.dt_end_tstz
  FROM schedule sch
 INNER JOIN sch_group sg ON (sg.id_schedule = sch.id_schedule)
 WHERE sch.id_sch_event IN (17, 1, 2, 3, 4, 10, 20)
   AND sch.dt_begin_tstz > (current_timestamp - 1)
	 AND sg.id_patient >= 0;
-- CHANGE END: Rita Lopes