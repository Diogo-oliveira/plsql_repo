-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 18-10-2010
-- CHANGE REASON: ALERT-104816
CREATE OR REPLACE VIEW V_APPOINTMENT AS
select a.code_appointment, 
       a.id_clinical_service, 
       a.id_sch_event, 
       a.flg_available,
       a.id_appointment
  from appointment a;
-- CHANGE END: Telmo Castro	
