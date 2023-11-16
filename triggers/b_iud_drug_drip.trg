CREATE OR REPLACE
TRIGGER b_iud_drug_drip
    BEFORE DELETE OR INSERT OR UPDATE ON drug_drip
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_drug_drip := 'DRUG_DRIP.CODE_DRUG_DRIP.' || :NEW.id_drug_drip;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_drip;
    ELSIF updating
    THEN
        :NEW.code_drug_drip  := 'DRUG_DRIP.CODE_DRUG_DRIP.' || :OLD.id_drug_drip;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
