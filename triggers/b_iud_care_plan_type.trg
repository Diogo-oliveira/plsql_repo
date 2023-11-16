CREATE OR REPLACE
TRIGGER b_iud_care_plan_type
    BEFORE DELETE OR INSERT OR UPDATE ON care_plan_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_care_plan_type := 'CARE_PLAN_TYPE.CODE_CARE_PLAN_TYPE.' || :NEW.id_care_plan_type;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_care_plan_type;
    ELSIF updating
    THEN
        :NEW.code_care_plan_type := 'CARE_PLAN_TYPE.CODE_CARE_PLAN_TYPE.' || :OLD.id_care_plan_type;
    END IF;
END b_iud_care_plan_type;
/
