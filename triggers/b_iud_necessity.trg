CREATE OR REPLACE
TRIGGER b_iud_necessity
    BEFORE DELETE OR INSERT OR UPDATE ON necessity
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_necessity := 'NECESSITY.CODE_NECESSITY.' || :NEW.id_necessity;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_necessity;
    ELSIF updating
    THEN
        :NEW.code_necessity  := 'NECESSITY.CODE_NECESSITY.' || :OLD.id_necessity;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
