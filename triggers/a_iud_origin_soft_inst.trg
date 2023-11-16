-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IUD_ORIGIN_SOFT_INST
  after insert or update or delete on ORIGIN_SOFT_INST
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.origin_soft_inst_new(:NEW.id_institution, :NEW.id_origin, :NEW.id_software);
  elsif updating then
    pk_ia_event_backoffice.origin_soft_inst_update(:NEW.id_institution, :NEW.id_origin, :NEW.id_software);
  elsif deleting then
    pk_ia_event_backoffice.origin_soft_inst_delete(:OLD.id_institution, :OLD.id_origin, :OLD.id_software);
  end if;
END A_IUD_ORIGIN_SOFT_INST;
/
-- CHANGE END: Telmo Castro