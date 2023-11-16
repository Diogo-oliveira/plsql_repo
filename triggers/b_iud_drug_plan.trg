CREATE OR REPLACE
TRIGGER b_iud_drug_plan
    BEFORE DELETE OR INSERT OR UPDATE ON drug_plan
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_drug_plan := 'DRUG_PLAN.CODE_DRUG_PLAN.' || :NEW.id_drug_plan;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_plan;
    ELSIF updating
    THEN
        :NEW.code_drug_plan := 'DRUG_PLAN.CODE_DRUG_PLAN.' || :OLD.id_drug_plan;
    END IF;
END;
/
