CREATE OR REPLACE
TRIGGER b_iud_criteria
    BEFORE DELETE OR INSERT OR UPDATE ON criteria
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_criteria := 'CRITERIA.CODE_CRITERIA.' || :NEW.id_criteria;
    
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_criteria;
    ELSIF updating
    THEN
        :NEW.code_criteria := 'CRITERIA.CODE_CRITERIA.' || :OLD.id_criteria;
    END IF;
END;
/
