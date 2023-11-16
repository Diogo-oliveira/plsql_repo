CREATE OR REPLACE
TRIGGER b_iu_system_organ
    BEFORE INSERT OR UPDATE OF code_system_organ, id_system_organ ON system_organ
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_system_organ := 'SYSTEM_ORGAN.CODE_SYSTEM_ORGAN.' || :NEW.id_system_organ;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_system_organ;
    ELSIF updating
    THEN
        :NEW.code_system_organ := 'SYSTEM_ORGAN.CODE_SYSTEM_ORGAN.' || :OLD.id_system_organ;
        :NEW.adw_last_update   := SYSDATE;

    END IF;
END;
/
