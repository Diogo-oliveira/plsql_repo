CREATE OR REPLACE
TRIGGER B_IUD_WL_QUEUE
 BEFORE DELETE OR INSERT OR UPDATE
 ON WL_QUEUE
 FOR EACH ROW
-- PL/SQL Block
BEGIN
    IF inserting
    THEN
        :NEW.adw_last_update := SYSDATE;

    ELSIF updating
    THEN
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
