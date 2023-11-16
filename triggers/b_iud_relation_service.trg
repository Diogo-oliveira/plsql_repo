CREATE OR REPLACE TRIGGER b_iud_relation_service
    BEFORE DELETE OR INSERT OR UPDATE ON relation_service
    FOR EACH ROW
BEGIN
    IF inserting
       OR updating
    THEN
        :NEW.code_relation_service := 'RELATION_SERVICE.CODE_RELATION_SERVICE.' || :NEW.id_relation_service;
        :NEW.code_warning          := 'RELATION_SERVICE.CODE_WARNING.' || :NEW.id_relation_service;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation IN (:OLD.code_relation_service, :OLD.code_warning)
           AND t.code_translation LIKE 'RELATION\_SERVICE.CODE\_%' ESCAPE '\';
    END IF;
END b_iud_relation_service;
