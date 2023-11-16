CREATE OR REPLACE TRIGGER B_IU_ANALYSIS_PROTOCOLS
 BEFORE INSERT OR UPDATE
 ON ANALYSIS_PROTOCOLS
 FOR EACH ROW
-- PL/SQL Block
BEGIN
:NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/
