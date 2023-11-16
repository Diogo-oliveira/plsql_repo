CREATE OR REPLACE
TRIGGER b_iud_drug_pharma
    BEFORE DELETE OR INSERT OR UPDATE ON drug_pharma
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_drug_pharma := 'DRUG_PHARMA.CODE_DRUG_PHARMA.' || :NEW.id_drug_pharma;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_pharma;
    ELSIF updating
    THEN
        :NEW.code_drug_pharma := 'DRUG_PHARMA.CODE_DRUG_PHARMA.' || :OLD.id_drug_pharma;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
