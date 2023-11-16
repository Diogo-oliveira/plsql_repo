-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IU_PROF_INSTITUTION
  after insert or update on PROF_INSTITUTION
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.prof_institution_new(:NEW.id_prof_institution, :NEW.id_institution);
  elsif updating then
    pk_ia_event_backoffice.prof_institution_update(:NEW.id_prof_institution, :NEW.id_institution);
  end if;
END A_IU_PROF_INSTITUTION;
/
-- CHANGE END: Telmo Castro