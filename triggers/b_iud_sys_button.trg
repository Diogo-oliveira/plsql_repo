CREATE OR REPLACE
TRIGGER b_iud_sys_button
    BEFORE DELETE OR INSERT OR UPDATE ON sys_button
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_button        := 'SYS_BUTTON.CODE_BUTTON.' || :NEW.id_sys_button;
        :NEW.code_icon          := 'SYS_BUTTON.CODE_ICON.' || :NEW.id_sys_button;
        :NEW.code_tooltip_title := 'SYS_BUTTON.CODE_TOOLTIP_TITLE.' || :NEW.id_sys_button;
        :NEW.code_tooltip_desc  := 'SYS_BUTTON.CODE_TOOLTIP_DESC.' || :NEW.id_sys_button;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_button
            OR code_translation = :OLD.code_icon
            OR code_translation = :OLD.code_tooltip_title
            OR code_translation = :OLD.code_tooltip_desc;
    ELSIF updating
    THEN
        :NEW.code_button        := 'SYS_BUTTON.CODE_BUTTON.' || :OLD.id_sys_button;
        :NEW.code_icon          := 'SYS_BUTTON.CODE_ICON.' || :OLD.id_sys_button;
        :NEW.code_tooltip_title := 'SYS_BUTTON.CODE_TOOLTIP_TITLE.' || :OLD.id_sys_button;
        :NEW.code_tooltip_desc  := 'SYS_BUTTON.CODE_TOOLTIP_DESC.' || :OLD.id_sys_button;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
