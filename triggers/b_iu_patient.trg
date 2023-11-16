CREATE OR REPLACE TRIGGER B_IU_PATIENT
 BEFORE INSERT OR UPDATE
 ON PATIENT
 FOR EACH ROW
-- PL/SQL Block
BEGIN
:NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/