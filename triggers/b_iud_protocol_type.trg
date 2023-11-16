CREATE OR REPLACE
TRIGGER b_iud_protocol_type
    BEFORE DELETE OR INSERT OR UPDATE ON protocol_type
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_protocol_type := 'PROTOCOL_TYPE.CODE_PROTOCOL_TYPE.' || :NEW.id_protocol_type;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_protocol_type;
    ELSIF updating
    THEN
        :NEW.code_protocol_type := 'PROTOCOL_TYPE.CODE_PROTOCOL_TYPE.' || :OLD.id_protocol_type;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
