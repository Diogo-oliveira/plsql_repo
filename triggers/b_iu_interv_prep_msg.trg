CREATE OR REPLACE TRIGGER B_IU_INTERV_PREP_MSG
 BEFORE INSERT OR UPDATE
 ON INTERV_PREP_MSG
 FOR EACH ROW
-- PL/SQL Block
BEGIN
:NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/
