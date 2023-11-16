CREATE OR REPLACE
TRIGGER b_iud_transp_entity
    BEFORE DELETE OR INSERT OR UPDATE ON transp_entity
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_transp_entity := 'TRANSP_ENTITY.CODE_TRANSP_ENTITY.' || :NEW.id_transp_entity;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_transp_entity;
    ELSIF updating
    THEN
        :NEW.code_transp_entity := 'TRANSP_ENTITY.CODE_TRANSP_ENTITY.' || :OLD.id_transp_entity;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
