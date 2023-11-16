CREATE OR REPLACE
TRIGGER b_iud_wound_type
    BEFORE DELETE OR INSERT OR UPDATE ON wound_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_wound_type      := 'WOUND_TYPE.CODE_WOUND_TYPE.' || :NEW.id_wound_type;
        :NEW.code_help_wound_type := 'WOUND_TYPE.CODE_HELP_WOUND_TYPE.' || :NEW.id_wound_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_wound_type
            OR code_translation = :OLD.code_help_wound_type;
    ELSIF updating
    THEN
        :NEW.code_wound_type      := 'WOUND_TYPE.CODE_WOUND_TYPE.' || :OLD.id_wound_type;
        :NEW.code_help_wound_type := 'WOUND_TYPE.CODE_HELP_WOUND_TYPE.' || :OLD.id_wound_type;
        :NEW.adw_last_update      := SYSDATE;
    END IF;
END;
/
