CREATE OR REPLACE
TRIGGER b_iud_audit_criteria
    BEFORE INSERT OR UPDATE ON audit_criteria
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_audit_criteria := 'AUDIT_CRITERIA.CODE_AUDIT_CRITERIA.' || :NEW.id_audit_criteria;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_audit_criteria;

    ELSIF updating
    THEN
        :NEW.code_audit_criteria := 'AUDIT_CRITERIA.CODE_AUDIT_CRITERIA.' || :NEW.id_audit_criteria;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
