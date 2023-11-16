CREATE OR REPLACE
TRIGGER b_iud_protocols
    BEFORE DELETE OR INSERT OR UPDATE ON protocols
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_protocols := 'PROTOCOLS.CODE_PROTOCOLS.' || :NEW.id_protocols;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_protocols;
    ELSIF updating
    THEN
        :NEW.code_protocols  := 'PROTOCOLS.CODE_PROTOCOLS.' || :OLD.id_protocols;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
