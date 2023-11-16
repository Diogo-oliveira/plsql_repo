CREATE OR REPLACE
TRIGGER b_iud_county
    BEFORE INSERT OR UPDATE OR DELETE ON county
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_county := 'COUNTY.CODE_COUNTY.' || :NEW.id_county;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_county;
    ELSIF updating
    THEN
        :NEW.code_county     := 'COUNTY.CODE_COUNTY.' || :OLD.id_county;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
