CREATE OR REPLACE
TRIGGER b_iud_exam_group
    BEFORE DELETE OR INSERT OR UPDATE ON exam_group
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_exam_group := 'EXAM_GROUP.CODE_EXAM_GROUP.' || :NEW.id_exam_group;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_exam_group;
    ELSIF updating
    THEN
        :NEW.code_exam_group := 'EXAM_GROUP.CODE_EXAM_GROUP.' || :OLD.id_exam_group;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
