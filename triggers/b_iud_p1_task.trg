CREATE OR REPLACE TRIGGER B_IUD_P1_TASK
    BEFORE DELETE OR INSERT OR UPDATE ON p1_task
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :new.code_task := 'P1_TASK.CODE_TASK.' || :new.id_task;
    
        :new.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :old.code_task;
    ELSIF updating
    THEN
        :new.code_task       := 'P1_TASK.CODE_TASK.' || :old.id_task;
        :new.adw_last_update := SYSDATE;
    END IF;
END;
/