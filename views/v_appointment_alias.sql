-- CHANGED BY: Telmo
-- CHANGED DATE: 15-09-2014
-- CHANGED REASON: alert-293762
create or replace view v_appointment_alias as
 select aa.id_appointment_alias,
        aa.id_sch_event_alias,
        aa.id_clinical_service,
        aa.code_appointment_alias,
        a.id_appointment
 from appointment_alias aa
 join sch_event_alias sea on aa.id_sch_event_alias = sea.id_sch_event_alias
 join appointment a on a.id_clinical_service = aa.id_clinical_service 
                    and a.id_sch_event = sea.id_sch_event;
-- CHANGE END: Telmo
