CREATE OR REPLACE
TRIGGER "ALERT".B_IU_TRANSLATION
 BEFORE INSERT OR UPDATE
 ON TRANSLATION
 FOR EACH ROW
-- PL/SQL Block
BEGIN
:NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/