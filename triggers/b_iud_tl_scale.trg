CREATE OR REPLACE
TRIGGER b_iud_tl_scale
    BEFORE DELETE OR INSERT OR UPDATE ON tl_scale
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_scale := 'TL_SCALE.CODE_SCALE.' || :NEW.id_tl_scale;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_scale;
    ELSIF updating
    THEN
        :NEW.code_scale      := 'TL_SCALE.CODE_SCALE.' || :OLD.id_tl_scale;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
