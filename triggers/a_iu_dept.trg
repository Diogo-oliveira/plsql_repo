-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IU_DEPT
  after insert or update on DEPT
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.dept_new(:NEW.id_institution, :NEW.id_dept);
  elsif updating then
    pk_ia_event_backoffice.dept_update(:NEW.id_institution, :NEW.id_dept);
  end if;
END A_IU_DEPT;
/
-- CHANGE END: Telmo Castro