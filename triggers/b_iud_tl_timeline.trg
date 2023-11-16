CREATE OR REPLACE
TRIGGER b_iud_tl_timeline
    BEFORE DELETE OR INSERT OR UPDATE ON tl_timeline
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_tl_timeline := 'TL_TIMELINE.CODE_TL_TIMELINE.' || :NEW.id_tl_timeline;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_tl_timeline;
    ELSIF updating
    THEN
        :NEW.code_tl_timeline := 'TL_TIMELINE.CODE_TL_TIMELINE.' || :OLD.id_tl_timeline;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
