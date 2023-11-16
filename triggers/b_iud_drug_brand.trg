CREATE OR REPLACE
TRIGGER b_iud_drug_brand
    BEFORE DELETE OR INSERT OR UPDATE ON drug_brand
    FOR EACH ROW
-- PL/SQL Block
BEGIN
    IF inserting
    THEN
        :NEW.code_drug_brand := 'DRUG_BRAND.CODE_DRUG_BRAND.' || :NEW.id_drug_brand;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_brand;
    ELSIF updating
    THEN
        :NEW.code_drug_brand := 'DRUG_BRAND.CODE_DRUG_BRAND.' || :OLD.id_drug_brand;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
