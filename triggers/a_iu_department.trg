-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IU_DEPARTMENT
  after insert or update on DEPARTMENT
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.department_new(:NEW.id_institution, :NEW.id_department);
  elsif updating then
    pk_ia_event_backoffice.department_update(:NEW.id_institution, :NEW.id_department);
  end if;
END A_IU_DEPARTMENT;
/
-- CHANGE END: Telmo Castro