CREATE OR REPLACE
TRIGGER b_uid_manipulated
    BEFORE DELETE OR INSERT OR UPDATE ON alert.manipulated
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_manipulated := 'MANIPULATED.CODE_MANIPULATED.' || :NEW.id_manipulated;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_manipulated;
    ELSIF updating
    THEN
        :NEW.code_manipulated := 'MANIPULATED.CODE_MANIPULATED.' || :OLD.id_manipulated;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
