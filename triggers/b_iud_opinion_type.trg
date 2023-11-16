CREATE OR REPLACE TRIGGER b_iud_opinion_type
    BEFORE DELETE OR INSERT OR UPDATE ON opinion_type
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_opinion_type := 'OPINION_TYPE.CODE_OPINION_TYPE.' || :NEW.id_opinion_type;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_opinion_type;
    ELSIF updating
    THEN
        :NEW.code_opinion_type := 'OPINION_TYPE.CODE_OPINION_TYPE.' || :OLD.id_opinion_type;
    END IF;
END b_iud_opinion_type;
/
