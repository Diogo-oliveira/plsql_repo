-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_U_APPOINTMENT
  after update of flg_available on APPOINTMENT
  for each row
BEGIN
  if :NEW.flg_available = 'Y' then
    pk_ia_event_backoffice.appointment_enable(:NEW.id_clinical_service, :NEW.id_sch_event);
  elsif :NEW.flg_available = 'N' then
    pk_ia_event_backoffice.appointment_disable(:NEW.id_clinical_service, :NEW.id_sch_event);
  end if;
END A_U_APPOINTMENT;
/
-- CHANGE END: Telmo Castro