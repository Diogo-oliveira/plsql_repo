CREATE OR REPLACE
TRIGGER b_iud_guideline_criteria_type
    BEFORE DELETE OR INSERT OR UPDATE ON guideline_criteria_type
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_guideline_criteria_type := 'GUIDELINE_CRITERIA_TYPE.CODE_GUIDELINE_CRITERIA_TYPE.' ||
                                             :NEW.id_guideline_criteria_type;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_guideline_criteria_type;
    ELSIF updating
    THEN
        :NEW.code_guideline_criteria_type := 'GUIDELINE_CRITERIA_TYPE.CODE_GUIDELINE_CRITERIA_TYPE.' ||
                                             :OLD.id_guideline_criteria_type;
        :NEW.adw_last_update              := SYSDATE;
    END IF;
END;
/
