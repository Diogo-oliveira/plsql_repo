CREATE OR REPLACE
TRIGGER b_uid_implementation
    BEFORE DELETE OR INSERT OR UPDATE ON implementation
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_implementation := 'IMPLEMENTATION.CODE_IMPLEMENTATION.' || :NEW.id_implementation;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_implementation;
    ELSIF updating
    THEN
        :NEW.code_implementation := 'IMPLEMENTATION.CODE_IMPLEMENTATION.' || :OLD.id_implementation;
    END IF;
END;
/
