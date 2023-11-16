CREATE OR REPLACE
TRIGGER b_iu_diagram_image
    BEFORE DELETE OR INSERT OR UPDATE ON diagram_image
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_diagram_image := 'DIAGRAM_IMAGE.CODE_DIAGRAM_IMAGE.' || :NEW.id_diagram_image;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_diagram_image;
    ELSIF updating
    THEN
        :NEW.code_diagram_image := 'DIAGRAM_IMAGE.CODE_DIAGRAM_IMAGE.' || :OLD.id_diagram_image;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
