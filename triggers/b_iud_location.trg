CREATE OR REPLACE
TRIGGER b_iud_location
    BEFORE DELETE OR INSERT OR UPDATE ON location
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_location := 'LOCATION.CODE_LOCATION.' || :NEW.id_location;

        :NEW.adw_date := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_location;
    ELSIF updating
    THEN
        :NEW.code_location := 'LOCATION.CODE_LOCATION.' || :OLD.id_location;
        :NEW.adw_date      := SYSDATE;
    END IF;
END;
/
