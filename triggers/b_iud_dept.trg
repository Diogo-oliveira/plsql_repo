CREATE OR REPLACE
TRIGGER b_iud_dept
    BEFORE DELETE OR INSERT OR UPDATE ON dept
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_dept := 'DEPT.CODE_DEPT.' || :NEW.id_dept;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_dept;
    ELSIF updating
    THEN
        :NEW.code_dept       := 'DEPT.CODE_DEPT.' || :OLD.id_dept;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
