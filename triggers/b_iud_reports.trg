CREATE OR REPLACE
TRIGGER b_iud_reports
    BEFORE DELETE OR INSERT OR UPDATE ON reports
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_reports       := 'REPORTS.CODE_REPORTS.' || :NEW.id_reports;
        :NEW.code_reports_title := 'REPORTS.CODE_REPORTS_TITLE.' || :NEW.id_reports;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_reports_title
            OR code_translation = :OLD.code_reports;

    ELSIF updating
    THEN
        :NEW.code_reports       := 'REPORTS.CODE_REPORTS.' || :OLD.id_reports;
        :NEW.code_reports_title := 'REPORTS.CODE_REPORTS_TITLE.' || :OLD.id_reports;
        :NEW.adw_last_update    := SYSDATE;

    END IF;
END;
/
