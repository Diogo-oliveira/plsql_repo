CREATE OR REPLACE
TRIGGER b_iu_diagram_layout
    BEFORE DELETE OR INSERT OR UPDATE ON diagram_layout
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_diagram_layout := 'DIAGRAM_LAYOUT.CODE_DIAGRAM_LAYOUT.' || :NEW.id_diagram_layout;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_diagram_layout;
    ELSIF updating
    THEN
        :NEW.code_diagram_layout := 'DIAGRAM_LAYOUT.CODE_DIAGRAM_LAYOUT.' || :OLD.id_diagram_layout;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
