CREATE OR REPLACE
TRIGGER b_iud_discharge_dest
    BEFORE DELETE OR INSERT OR UPDATE ON discharge_dest
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_discharge_dest := 'DISCHARGE_DEST.CODE_DISCHARGE_DEST.' || :NEW.id_discharge_dest;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_discharge_dest;
    ELSIF updating
    THEN
        :NEW.code_discharge_dest := 'DISCHARGE_DEST.CODE_DISCHARGE_DEST.' || :OLD.id_discharge_dest;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
