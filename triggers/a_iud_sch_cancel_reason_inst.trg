-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_388
create or replace trigger A_IUD_SCH_CANCEL_REASON_INST
  after insert or update or delete on SCH_CANCEL_REASON_INST
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.sch_cancel_reason_inst_new(:NEW.id_institution, :NEW.id_sch_cancel_reason_inst);
  elsif updating then
    pk_ia_event_backoffice.sch_cancel_reason_inst_update(:NEW.id_institution, :NEW.id_sch_cancel_reason_inst);
  elsif deleting then
    pk_ia_event_backoffice.sch_cancel_reason_inst_delete(:OLD.id_institution, :OLD.id_sch_cancel_reason_inst, :OLD.id_sch_cancel_reason,:OLD.id_software);
  end if;
END A_IUD_SCH_CANCEL_REASON_INST;
/
-- CHANGE END: Telmo Castro