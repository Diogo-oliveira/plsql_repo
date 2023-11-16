CREATE OR REPLACE
TRIGGER b_iud_reports_section
    BEFORE DELETE OR INSERT OR UPDATE ON alert.rep_section
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_rep_section := 'REP_SECTION.CODE_REP_SECTION.' || :NEW.id_rep_section;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_rep_section;
    ELSIF updating
    THEN
        :NEW.code_rep_section := 'REP_SECTION.CODE_REP_SECTION.' || :OLD.id_rep_section;
        :NEW.adw_last_update  := SYSDATE;

    END IF;
END;
/
