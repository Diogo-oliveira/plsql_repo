CREATE OR REPLACE
TRIGGER b_iud_exam_alias
    BEFORE DELETE OR INSERT OR UPDATE ON exam_alias
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_exam_alias := 'EXAM_ALIAS.CODE_EXAM_ALIAS.' || :NEW.id_exam_alias;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_exam_alias;

    ELSIF updating
    THEN
        :NEW.code_exam_alias := 'EXAM_ALIAS.CODE_EXAM_ALIAS.' || :OLD.id_exam_alias;
        :NEW.adw_last_update := SYSDATE;

    END IF;
END;
/
