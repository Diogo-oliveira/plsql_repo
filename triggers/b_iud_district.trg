CREATE OR REPLACE
TRIGGER b_iud_district
    BEFORE DELETE OR INSERT OR UPDATE ON district
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_district := 'DISTRICT.CODE_DISTRICT.' || :NEW.id_district;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_district;
    ELSIF updating
    THEN
        :NEW.code_district   := 'DISTRICT.CODE_DISTRICT.' || :OLD.id_district;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
