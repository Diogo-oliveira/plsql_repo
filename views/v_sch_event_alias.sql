-- CHANGED BY: Telmo
-- CHANGED DATE: 15-09-2014
-- CHANGED REASON: alert-293762
create view v_sch_event_alias as
 select sea.id_sch_event_alias,
        sea.id_sch_event,
        sea.id_institution,
        sea.code_sch_event_alias
 from sch_event_alias sea;
-- CHANGE END: Telmo
