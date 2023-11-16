-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IUD_INSTITUTION
  after insert or update or delete on INSTITUTION
  for each row
BEGIN
    -- FACILITY_NEW
    IF (inserting AND :NEW.id_parent IS NOT NULL)
       OR (updating AND :OLD.id_parent IS NULL AND :NEW.id_parent IS NOT NULL)
    THEN
        pk_ia_event_backoffice.facility_new(:NEW.id_institution);
        -- FACILITY_UPDATE 
    ELSIF (updating AND :OLD.id_parent IS NOT NULL AND :NEW.id_parent IS NOT NULL)
    THEN
        pk_ia_event_backoffice.facility_update(:NEW.id_institution);
        -- FACILITY_DELETE 
    ELSIF (deleting AND :OLD.id_parent IS NOT NULL)
          OR (updating AND :OLD.id_parent IS NOT NULL AND :NEW.id_parent IS NULL)
    THEN
        pk_ia_event_backoffice.facility_delete(:OLD.id_institution);
    END IF;

    -- INSTITUTION_NEW
    IF (inserting)
    THEN
        pk_ia_event_backoffice.institution_new(:NEW.id_institution);
    ELSIF (updating)
    THEN
        pk_ia_event_backoffice.institution_update(:NEW.id_institution);
    END IF;

END a_iud_institution;
/
-- CHANGE END: Telmo Castro