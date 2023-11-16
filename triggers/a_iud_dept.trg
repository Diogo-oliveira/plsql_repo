-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 06-04-2010
-- CHANGE REASON: SCH-510
create or replace trigger A_IUD_DEPT
  after insert or update or delete on DEPT
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.dept_new(:NEW.id_institution, :NEW.id_dept);
  elsif updating then
    pk_ia_event_backoffice.dept_update(:NEW.id_institution, :NEW.id_dept);
  elsif deleting then
  	pk_ia_event_backoffice.dept_delete(:OLD.id_institution,:OLD.id_dept);
  end if;
END A_IUD_DEPT;
/
-- CHANGE END: Telmo Castro