-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
create or replace view v_sch_upg_schedules_app as
select v.*, so.id_schedule_outp, a.id_appointment id_content_app
from v_sch_upg_schedules v
  JOIN alert.schedule_outp so ON v.id_schedule = so.id_schedule
  JOIN alert.appointment a on a.id_clinical_service = v.id_clinical_service AND a.id_sch_event = v.id_sch_event
WHERE v.flg_sch_type IN ('C', 'N', 'U', 'AS')
and a.id_appointment is not null;
-- CHANGE END: Telmo
