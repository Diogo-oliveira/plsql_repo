CREATE OR REPLACE TRIGGER b_iud_relation_type
    BEFORE DELETE OR INSERT OR UPDATE ON relation_type
    FOR EACH ROW
BEGIN
    IF inserting
       OR updating
    THEN
        :NEW.code_relation_type := 'RELATION_TYPE.CODE_RELATION_TYPE.' || :NEW.id_relation_type;
        :NEW.code_warning       := 'RELATION_TYPE.CODE_WARNING.' || :NEW.id_relation_type;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation IN (:OLD.code_relation_type, :OLD.code_warning)
           AND t.code_translation LIKE 'RELATION\_TYPE.CODE\_%' ESCAPE '\';
    END IF;
END b_iud_relation_type;
