CREATE OR REPLACE
TRIGGER b_iud_periodic_exam_educ
    BEFORE DELETE OR INSERT OR UPDATE ON periodic_exam_educ
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_periodic_exam_educ := 'PERIODIC_EXAM_EDUC.CODE_PERIODIC_EXAM_EDUC.' || :NEW.id_periodic_exam_educ;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_periodic_exam_educ;
    ELSIF updating
    THEN
        :NEW.code_periodic_exam_educ := 'PERIODIC_EXAM_EDUC.CODE_PERIODIC_EXAM_EDUC.' || :OLD.id_periodic_exam_educ;
        :NEW.adw_last_update         := SYSDATE;
    END IF;
END;
/
