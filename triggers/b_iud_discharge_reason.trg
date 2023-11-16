CREATE OR REPLACE
TRIGGER b_iud_discharge_reason
    BEFORE DELETE OR INSERT OR UPDATE ON discharge_reason
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_discharge_reason := 'DISCHARGE_REASON.CODE_DISCHARGE_REASON.' || :NEW.id_discharge_reason;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_discharge_reason;
    ELSIF updating
    THEN
        :NEW.code_discharge_reason := 'DISCHARGE_REASON.CODE_DISCHARGE_REASON.' || :OLD.id_discharge_reason;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/
