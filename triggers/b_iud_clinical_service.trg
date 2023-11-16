CREATE OR REPLACE
TRIGGER b_iud_clinical_service
    BEFORE DELETE OR INSERT OR UPDATE ON clinical_service
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_clinical_service := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || :NEW.id_clinical_service;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_clinical_service;
    ELSIF updating
    THEN
        :NEW.code_clinical_service := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || :OLD.id_clinical_service;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/
