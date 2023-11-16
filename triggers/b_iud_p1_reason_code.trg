CREATE OR REPLACE
TRIGGER b_iud_p1_reason_code
    BEFORE DELETE OR INSERT OR UPDATE ON p1_reason_code
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_reason := 'P1_REASON_CODE.CODE_REASON.' || :NEW.id_reason_code;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_reason;
    ELSIF updating
    THEN
        :NEW.code_reason     := 'P1_REASON_CODE.CODE_REASON.' || :OLD.id_reason_code;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
