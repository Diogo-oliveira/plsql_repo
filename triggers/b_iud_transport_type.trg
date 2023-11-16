CREATE OR REPLACE
TRIGGER b_iud_transport_type
    BEFORE DELETE OR INSERT OR UPDATE ON transport_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_transport_type := 'TRANSPORT_TYPE.CODE_TRANSPORT_TYPE.' || :NEW.id_transport_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_transport_type;
    ELSIF updating
    THEN
        :NEW.code_transport_type := 'TRANSPORT_TYPE.CODE_TRANSPORT_TYPE.' || :OLD.id_transport_type;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
