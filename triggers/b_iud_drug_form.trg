CREATE OR REPLACE
TRIGGER b_iud_drug_form
    BEFORE DELETE OR INSERT OR UPDATE ON drug_form
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_drug_form := 'DRUG_FORM.CODE_DRUG_FORM.' || :NEW.id_drug_form;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_form;
    ELSIF updating
    THEN
        :NEW.code_drug_form  := 'DRUG_FORM.CODE_DRUG_FORM.' || :OLD.id_drug_form;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
