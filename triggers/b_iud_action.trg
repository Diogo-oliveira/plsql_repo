CREATE OR REPLACE
TRIGGER b_iud_action
    BEFORE DELETE OR INSERT OR UPDATE ON action
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_action := 'ACTION.CODE_ACTION.' || :NEW.id_action;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_action;
    ELSIF updating
    THEN
        :NEW.code_action     := 'ACTION.CODE_ACTION.' || :OLD.id_action;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
