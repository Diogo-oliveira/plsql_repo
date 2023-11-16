CREATE OR REPLACE
TRIGGER b_iud_drug_despachos
    BEFORE DELETE OR INSERT OR UPDATE ON drug_despachos
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_drug_despachos := 'DRUG_DESPACHOS.CODE_DRUG_DESPACHOS.' || :NEW.id_drug_despachos;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_despachos;
    ELSIF updating
    THEN
        :NEW.code_drug_despachos := 'DRUG_DESPACHOS.CODE_DRUG_DESPACHOS.' || :OLD.id_drug_despachos;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
