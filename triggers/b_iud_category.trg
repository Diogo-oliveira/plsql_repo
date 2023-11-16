CREATE OR REPLACE
TRIGGER b_iud_category
    BEFORE DELETE OR INSERT OR UPDATE ON category
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_category := 'CATEGORY.CODE_CATEGORY.' || :NEW.id_category;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_category;
    ELSIF updating
    THEN
        :NEW.code_category := 'CATEGORY.CODE_CATEGORY.' || :OLD.id_category;

    END IF;
END;
/
