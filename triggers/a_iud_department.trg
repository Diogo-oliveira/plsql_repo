-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 06-04-2010
-- CHANGE REASON: SCH-510
create or replace trigger A_IUD_DEPARTMENT
  after insert or update or delete on DEPARTMENT
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.department_new(:NEW.id_institution, :NEW.id_department);
  elsif updating then
    pk_ia_event_backoffice.department_update(:NEW.id_institution, :NEW.id_department);
  elsif deleting then
  	pk_ia_event_backoffice.department_delete(:OLD.id_institution, :OLD.id_department, :OLD.id_dept);
  end if;
END A_IUD_DEPARTMENT;
/
-- CHANGE END: Telmo Castro
