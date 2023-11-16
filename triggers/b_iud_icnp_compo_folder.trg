CREATE OR REPLACE
TRIGGER b_iud_icnp_compo_folder
    BEFORE DELETE OR INSERT OR UPDATE ON icnp_folder
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_folder := 'ICNP_COMPO_FOLDER.CODE_FOLDER.' || :NEW.id_folder;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_folder;
    ELSIF updating
    THEN
        :NEW.code_folder     := 'ICNP_COMPO_FOLDER.CODE_FOLDER.' || :OLD.id_folder;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
