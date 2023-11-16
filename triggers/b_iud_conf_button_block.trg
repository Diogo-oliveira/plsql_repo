CREATE OR REPLACE TRIGGER b_iud_conf_button_block
    BEFORE DELETE OR INSERT OR UPDATE ON conf_button_block
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_conf_button_block := 'CONF_BUTTON_BLOCK.CODE_CONF_BUTTON_BLOCK.' || :NEW.id_conf_button_block;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :OLD.code_conf_button_block
           AND t.code_translation LIKE 'CONF\_BUTTON\_BLOCK.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :NEW.code_conf_button_block := 'CONF_BUTTON_BLOCK.CODE_CONF_BUTTON_BLOCK.' || :OLD.id_conf_button_block;
    END IF;
END b_iud_conf_button_block;
/
