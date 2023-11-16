-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
create or replace view v_sch_upg_schedules_with_dtend as
  select v.*, 
        NVL(v.dt_end_tstz, 
            (select dt_end_tstz from sch_consult_vacancy where id_sch_consult_vacancy = v.id_sch_consult_vacancy)) best_dt_end
  from v_sch_upg_schedules v;
-- CHANGE END: Telmo