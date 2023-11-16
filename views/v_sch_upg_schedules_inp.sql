-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
create or replace view v_sch_upg_schedules_inp as
select v.*
from v_sch_upg_schedules v
  JOIN alert.schedule_bed b on v.id_schedule = b.id_schedule
WHERE v.flg_sch_type = 'IN';
-- CHANGE END: Telmo