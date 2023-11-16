CREATE OR REPLACE
TRIGGER b_iud_summary_page
    BEFORE DELETE OR INSERT OR UPDATE ON summary_page
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_summary_page := 'SUMMARY_PAGE.CODE_SUMMARY_PAGE.' || :NEW.id_summary_page;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_summary_page;

    ELSIF updating
    THEN
        :NEW.code_summary_page := 'SUMMARY_PAGE.CODE_SUMMARY_PAGE.' || :OLD.id_summary_page;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
