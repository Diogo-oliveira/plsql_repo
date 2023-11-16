-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
create or replace view v_sch_upg_schedules_exam as
select v.*, se.id_exam, se.id_schedule_exam, e.id_content id_content_exam
from v_sch_upg_schedules v
  JOIN alert.schedule_exam se ON v.id_schedule = se.id_schedule
  JOIN alert.exam e ON e.id_exam = se.id_exam
where v.flg_sch_type IN ('E', 'X');
-- CHANGE END: Telmo
