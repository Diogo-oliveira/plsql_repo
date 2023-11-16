CREATE OR REPLACE TRIGGER B_IU_PAT_CLI_ATTRIBUTES
 BEFORE INSERT OR UPDATE
 ON PAT_CLI_ATTRIBUTES
 FOR EACH ROW
-- PL/SQL Block
BEGIN
:NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/
