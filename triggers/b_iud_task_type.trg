CREATE OR REPLACE
TRIGGER b_iud_task_type
    BEFORE DELETE OR INSERT OR UPDATE ON task_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_task_type := 'TASK_TYPE.CODE_TASK_TYPE.' || :NEW.id_task_type;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_task_type;
    ELSIF updating
    THEN
        :NEW.code_task_type := 'TASK_TYPE.CODE_TASK_TYPE.' || :OLD.id_task_type;
    END IF;
END;
/
