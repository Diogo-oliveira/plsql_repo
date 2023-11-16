CREATE OR REPLACE TRIGGER B_IU_INST_ATTRIBUTES
 BEFORE INSERT OR UPDATE
 ON INST_ATTRIBUTES
 FOR EACH ROW
-- PL/SQL Block
DECLARE
    -- local variables here
BEGIN
    :NEW.adw_last_update := SYSDATE;
END;
/