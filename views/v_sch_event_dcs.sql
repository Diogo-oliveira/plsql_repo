-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_386
create or replace view v_sch_event_dcs as
select s.id_sch_event_dcs, 
       s.id_sch_event, 
       s.id_dep_clin_serv, 
       s.duration, 
       s.id_prof_created, 
       s.dt_created, 
       s.id_prof_updated, 
       s.dt_updated, 
       s.flg_available 
  from sch_event_dcs s;
  
-- CHANGE END: Telmo Castro