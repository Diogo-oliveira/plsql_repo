CREATE OR REPLACE
TRIGGER b_iud_drug_pharma_class
    BEFORE DELETE OR INSERT OR UPDATE ON drug_pharma_class
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_drug_pharma_class := 'DRUG_PHARMA_CLASS.CODE_DRUG_PHARMA_CLASS.' || :NEW.id_drug_pharma_class;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_pharma_class;
    ELSIF updating
    THEN
        :NEW.code_drug_pharma_class := 'DRUG_PHARMA_CLASS.CODE_DRUG_PHARMA_CLASS.' || :OLD.id_drug_pharma_class;
        :NEW.adw_last_update        := SYSDATE;
    END IF;
END;
/
