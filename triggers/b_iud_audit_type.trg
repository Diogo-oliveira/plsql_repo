CREATE OR REPLACE
TRIGGER b_iud_audit_type
    BEFORE DELETE OR INSERT OR UPDATE ON audit_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_audit_type   := 'AUDIT_TYPE.CODE_AUDIT_TYPE.' || :NEW.id_audit_type;
        :NEW.code_abbreviation := 'AUDIT_TYPE.CODE_ABBREVIATION.' || :NEW.id_audit_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_audit_type
            OR code_translation = :OLD.code_abbreviation;

    ELSIF updating
    THEN
        :NEW.code_audit_type   := 'AUDIT_TYPE.CODE_AUDIT_TYPE.' || :NEW.id_audit_type;
        :NEW.code_abbreviation := 'AUDIT_TYPE.CODE_ABBREVIATION.' || :NEW.id_audit_type;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
