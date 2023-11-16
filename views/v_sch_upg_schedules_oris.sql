-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
create or replace view v_sch_upg_schedules_oris as
select v.*, sr.id_schedule_sr, si.id_content
from v_sch_upg_schedules v
  JOIN schedule_sr sr on v.id_schedule = sr.id_schedule
  LEFT JOIN sr_epis_interv sei ON sr.id_episode = sei.id_episode_context
  LEFT join intervention si on sei.id_sr_intervention = si.id_intervention
where v.flg_sch_type = 'S';
-- CHANGE END: Telmo
