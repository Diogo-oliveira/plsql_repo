CREATE OR REPLACE
TRIGGER B_IUD_UNIDOSE_CAR
 BEFORE DELETE OR INSERT OR UPDATE
 ON UNIDOSE_CAR
 FOR EACH ROW
-- PL/SQL Block
BEGIN
    IF inserting
    THEN
        :NEW.adw_last_update := SYSDATE;
    ELSIF updating
    THEN
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
