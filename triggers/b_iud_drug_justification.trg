CREATE OR REPLACE
TRIGGER b_iud_drug_justification
    BEFORE DELETE OR INSERT OR UPDATE ON alert.drug_justification
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_drug_justification := 'DRUG_JUSTIFICATION.CODE_DRUG_JUSTIFICATION.' || :NEW.id_drug_justification;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_justification;
    ELSIF updating
    THEN
        :NEW.code_drug_justification := 'DRUG_JUSTIFICATION.CODE_DRUG_JUSTIFICATION.' || :OLD.id_drug_justification;
        :NEW.adw_last_update         := SYSDATE;
    END IF;
END;
/
