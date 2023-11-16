-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
create or replace view v_sch_upg_schedules_mfr as
select v.*
from v_sch_upg_schedules v
join schedule_intervention si on v.id_schedule = si.id_schedule
join interv_presc_det ipd on si.id_interv_presc_det = ipd.id_interv_presc_det
join intervention i on ipd.id_intervention = i.id_intervention
where v.flg_sch_type = 'PM';
-- CHANGE END: Telmo