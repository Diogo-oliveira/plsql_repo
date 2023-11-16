CREATE OR REPLACE
TRIGGER b_iud_institution
    BEFORE DELETE OR INSERT OR UPDATE ON institution
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_institution := 'INSTITUTION.CODE_INSTITUTION.' || :NEW.id_institution;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_institution;
    ELSIF updating
    THEN
        :NEW.code_institution := 'INSTITUTION.CODE_INSTITUTION.' || :OLD.id_institution;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
