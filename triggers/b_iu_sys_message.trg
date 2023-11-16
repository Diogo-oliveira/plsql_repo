CREATE OR REPLACE TRIGGER B_IU_SYS_MESSAGE
 BEFORE INSERT OR UPDATE
 ON SYS_MESSAGE
 FOR EACH ROW

-- PL/SQL Block
BEGIN
:NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/