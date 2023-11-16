CREATE OR REPLACE
TRIGGER b_iud_sch_cancel_reason
    BEFORE DELETE OR INSERT OR UPDATE ON sch_cancel_reason
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_cancel_reason := 'SCH_CANCEL_REASON.CODE_CANCEL_REASON.' || :NEW.id_sch_cancel_reason;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_cancel_reason;
    ELSIF updating
    THEN
        :NEW.code_cancel_reason := 'SCH_CANCEL_REASON.CODE_CANCEL_REASON.' || :OLD.id_sch_cancel_reason;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
