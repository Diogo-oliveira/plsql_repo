CREATE OR REPLACE
TRIGGER b_iud_department
    BEFORE DELETE OR INSERT OR UPDATE ON department
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_department := 'DEPARTMENT.CODE_DEPARTMENT.' || :NEW.id_department;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_department;
    ELSIF updating
    THEN
        :NEW.code_department := 'DEPARTMENT.CODE_DEPARTMENT.' || :OLD.id_department;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
