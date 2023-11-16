CREATE OR REPLACE
TRIGGER b_iud_recm
    BEFORE DELETE OR INSERT OR UPDATE ON recm
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_recm := 'RECM.CODE_RECM.' || :NEW.id_recm;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_recm;
    ELSIF updating
    THEN
        :NEW.code_recm       := 'RECM.CODE_RECM.' || :OLD.id_recm;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
