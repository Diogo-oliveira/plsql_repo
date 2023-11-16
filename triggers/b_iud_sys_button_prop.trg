CREATE OR REPLACE
TRIGGER b_iud_sys_button_prop
    BEFORE DELETE OR INSERT OR UPDATE ON sys_button_prop
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_title_help    := 'SYS_BUTTON_PROP.CODE_TITLE_HELP.' || :NEW.id_sys_button_prop;
        :NEW.code_desc_help     := 'SYS_BUTTON_PROP.CODE_DESC_HELP.' || :NEW.id_sys_button_prop;
        :NEW.code_tooltip_title := 'SYS_BUTTON_PROP.CODE_TOOLTIP_TITLE.' || :NEW.id_sys_button_prop;
        :NEW.code_tooltip_desc  := 'SYS_BUTTON_PROP.CODE_TOOLTIP_DESC.' || :NEW.id_sys_button_prop;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE (code_translation = :OLD.code_title_help OR code_translation = :OLD.code_desc_help OR
               code_translation = :OLD.code_tooltip_title OR code_translation = :OLD.code_tooltip_desc)
           AND code_translation LIKE 'SYS\_BUTTON\_PROP.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :NEW.code_title_help := 'SYS_BUTTON_PROP.CODE_TITLE_HELP.' || :OLD.id_sys_button_prop;
        :NEW.code_desc_help  := 'SYS_BUTTON_PROP.CODE_DESC_HELP.' || :OLD.id_sys_button_prop;
        :NEW.code_desc_help  := 'SYS_BUTTON_PROP.CODE_TOOLTIP_TITLE.' || :OLD.id_sys_button_prop;
        :NEW.code_desc_help  := 'SYS_BUTTON_PROP.CODE_TOOLTIP_DESC.' || :OLD.id_sys_button_prop;
    END IF;
END;
/
