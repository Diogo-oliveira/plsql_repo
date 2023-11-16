CREATE OR REPLACE
TRIGGER b_iud_exam
    BEFORE DELETE OR INSERT OR UPDATE ON exam
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_exam := 'EXAM.CODE_EXAM.' || :NEW.id_exam;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_exam;
    ELSIF updating
    THEN
        :NEW.code_exam       := 'EXAM.CODE_EXAM.' || :OLD.id_exam;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
