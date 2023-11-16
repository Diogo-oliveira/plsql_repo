CREATE OR REPLACE
TRIGGER b_iud_drug_take_time
    BEFORE DELETE OR INSERT OR UPDATE ON drug_take_time
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_drug_take_time := 'DRUG_TAKE_TIME.CODE_DRUG_TAKE_TIME.' || :NEW.id_drug_take_time;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_take_time;
    ELSIF updating
    THEN
        :NEW.code_drug_take_time := 'DRUG_TAKE_TIME.CODE_DRUG_TAKE_TIME.' || :OLD.id_drug_take_time;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
