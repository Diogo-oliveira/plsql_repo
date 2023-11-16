CREATE OR REPLACE
TRIGGER b_iu_body_layer
    BEFORE DELETE OR INSERT OR UPDATE ON body_layer
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_body_layer := 'BODY_LAYER.CODE_BODY_LAYER.' || :NEW.id_body_layer;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_body_layer;
    ELSIF updating
    THEN
        :NEW.code_body_layer := 'BODY_LAYER.CODE_BODY_LAYER.' || :OLD.id_body_layer;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
