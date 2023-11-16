CREATE OR REPLACE
TRIGGER b_iud_diagram_tools_group
    BEFORE DELETE OR INSERT OR UPDATE ON diagram_tools_group
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_diagram_tools_group := 'DIAGRAM_TOOLS_GROUP.CODE_DIAGRAM_TOOLS_GROUP.' || :NEW.id_diagram_tools_group;
        :NEW.code_acronym_group       := 'DIAGRAM_TOOLS_GROUP.CODE_ACRONYM_GROUP.' || :NEW.id_diagram_tools_group;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_diagram_tools_group
            OR code_translation = :OLD.code_acronym_group;
    ELSIF updating
    THEN
        :NEW.code_diagram_tools_group := 'DIAGRAM_TOOLS_GROUP.CODE_DIAGRAM_TOOLS_GROUP.' || :OLD.id_diagram_tools_group;
        :NEW.code_acronym_group       := 'DIAGRAM_TOOLS_GROUP.CODE_ACRONYM_GROUP.' || :OLD.id_diagram_tools_group;
        :NEW.adw_last_update          := SYSDATE;
    END IF;
END;
/
