-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IUD_SCH_CANCEL_REASON
  after insert or update or delete on SCH_CANCEL_REASON
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.sch_cancel_reason_new(:NEW.id_sch_cancel_reason);
  elsif updating then
    pk_ia_event_backoffice.sch_cancel_reason_update(:NEW.id_sch_cancel_reason);
  elsif deleting then
    pk_ia_event_backoffice.sch_cancel_reason_delete(:OLD.id_sch_cancel_reason);
  end if;
END A_IUD_SCH_CANCEL_REASON;
/
-- CHANGE END: Telmo Castro