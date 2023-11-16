-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IU_COUNTRY
  after insert or update on COUNTRY
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.country_new(:NEW.id_country);
  elsif updating then
    pk_ia_event_backoffice.country_update(:NEW.id_country);
  end if;
END A_IU_COUNTRY;
/
-- CHANGE END: Telmo Castro