CREATE OR REPLACE TRIGGER B_IU_EVAL_MNG
 BEFORE INSERT OR UPDATE
 ON EVAL_MNG
 FOR EACH ROW
-- PL/SQL Block
BEGIN
:NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/
