CREATE OR REPLACE
TRIGGER b_iud_epis_type
    BEFORE DELETE OR INSERT OR UPDATE ON epis_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_epis_type := 'EPIS_TYPE.CODE_EPIS_TYPE.' || :NEW.id_epis_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_epis_type;
    ELSIF updating
    THEN
        :NEW.code_epis_type  := 'EPIS_TYPE.CODE_EPIS_TYPE.' || :OLD.id_epis_type;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
