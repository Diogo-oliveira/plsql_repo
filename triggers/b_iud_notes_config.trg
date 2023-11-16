CREATE OR REPLACE
TRIGGER b_iud_notes_config
    BEFORE DELETE OR UPDATE OR INSERT ON notes_config
    FOR EACH ROW
BEGIN

    IF inserting
    THEN
        :NEW.code_notes_config := 'NOTES_CONFIG.CODE_NOTES_CONFIG.' || :NEW.id_notes_config;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_notes_config;
    ELSIF updating
    THEN
        :NEW.code_notes_config := 'NOTES_CONFIG.CODE_NOTES_CONFIG.' || :OLD.id_notes_config;
        :NEW.adw_last_update   := SYSDATE;
    END IF;

END b_iud_notes_config;
/
