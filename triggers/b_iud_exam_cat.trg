CREATE OR REPLACE
TRIGGER b_iud_exam_cat
    BEFORE DELETE OR INSERT OR UPDATE ON exam_cat
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_exam_cat := 'EXAM_CAT.CODE_EXAM_CAT.' || :NEW.id_exam_cat;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_exam_cat;
    ELSIF updating
    THEN
        :NEW.code_exam_cat   := 'EXAM_CAT.CODE_EXAM_CAT.' || :OLD.id_exam_cat;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
