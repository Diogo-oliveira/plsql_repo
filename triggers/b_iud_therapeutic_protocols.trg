CREATE OR REPLACE
TRIGGER b_iud_therapeutic_protocols
    BEFORE DELETE OR INSERT OR UPDATE ON therapeutic_protocols
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_therapeutic_protocols := 'THERAPEUTIC_PROTOCOLS.CODE_THERAPEUTIC_PROTOCOLS.' ||
                                           :NEW.id_therapeutic_protocols;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_therapeutic_protocols;
    ELSIF updating
    THEN
        :NEW.code_therapeutic_protocols := 'THERAPEUTIC_PROTOCOLS.CODE_THERAPEUTIC_PROTOCOLS.' ||
                                           :OLD.id_therapeutic_protocols;
        :NEW.adw_last_update            := SYSDATE;
    END IF;
END;
/
