CREATE OR REPLACE
TRIGGER b_iud_city
    BEFORE DELETE OR INSERT OR UPDATE ON city
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_city := 'CITY.CODE_CITY.' || :NEW.id_city;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_city;
    ELSIF updating
    THEN
        :NEW.code_city       := 'CITY.CODE_CITY.' || :OLD.id_city;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
