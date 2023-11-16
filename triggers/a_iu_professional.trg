-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IU_PROFESSIONAL
  after insert or update on PROFESSIONAL
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.professional_new(i_id_professional => :NEW.id_professional);
  elsif updating then
    pk_ia_event_backoffice.professional_update(i_id_professional => :NEW.id_professional);
  end if;
END A_IU_PROF_INSTITUTION;
/
-- CHANGE END: Telmo Castro

-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 30-09-2019
-- CHANGE REASON: EMR-21126
DROP TRIGGER A_IU_PROFESSIONAL;
-- CHANGE END: Diogo Oliveira