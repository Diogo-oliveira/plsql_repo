CREATE OR REPLACE
TRIGGER b_iud_wound_charac
    BEFORE DELETE OR INSERT OR UPDATE ON wound_charac
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_wound_charac := 'WOUND_CHARAC.CODE_WOUND_CHARAC.' || :NEW.id_wound_charac;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_wound_charac;
    ELSIF updating
    THEN
        :NEW.code_wound_charac := 'WOUND_CHARAC.CODE_WOUND_CHARAC.' || :OLD.id_wound_charac;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
