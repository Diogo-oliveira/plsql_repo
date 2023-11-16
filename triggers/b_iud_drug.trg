CREATE OR REPLACE
TRIGGER b_iud_drug
    BEFORE DELETE OR INSERT OR UPDATE ON drug
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_drug := 'DRUG.CODE_DRUG.' || :NEW.id_drug;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug;
    ELSIF updating
    THEN
        :NEW.code_drug       := 'DRUG.CODE_DRUG.' || :OLD.id_drug;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
