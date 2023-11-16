CREATE OR REPLACE
TRIGGER b_iud_complaint
    BEFORE DELETE OR INSERT OR UPDATE ON complaint
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_complaint := 'COMPLAINT.CODE_COMPLAINT.' || :NEW.id_complaint;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_complaint;
    ELSIF updating
    THEN
        :NEW.code_complaint  := 'COMPLAINT.CODE_COMPLAINT.' || :OLD.id_complaint;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
