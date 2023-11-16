-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410
CREATE OR REPLACE TRIGGER A_IU_SOFT_INSTIT
  AFTER INSERT OR UPDATE ON SOFTWARE_INSTITUTION
  FOR EACH ROW
BEGIN
  IF INSERTING THEN
    pk_ia_event_backoffice.soft_inst_new(:NEW.id_software_institution, :NEW.id_institution);
  ELSIF UPDATING THEN
    pk_ia_event_backoffice.soft_inst_update(:NEW.id_software_institution, :NEW.id_institution);
  END IF;
END A_IU_SOFT_INSTIT;
-- CHANGE END: Telmo Castro