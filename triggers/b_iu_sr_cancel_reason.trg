CREATE OR REPLACE
TRIGGER b_iu_sr_cancel_reason
    BEFORE INSERT OR UPDATE OF id_sr_cancel_reason ON sr_cancel_reason
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sr_cancel_reason := 'SR_CANCEL_REASON.CODE_SR_SR_CANCEL_REASON.' || :NEW.id_sr_cancel_reason;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sr_cancel_reason;
    ELSIF updating
    THEN
        :NEW.code_sr_cancel_reason := 'SR_CANCEL_REASON.CODE_SR_CANCEL_REASON.' || :OLD.id_sr_cancel_reason;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/


drop trigger alert.b_iu_sr_cancel_reason;