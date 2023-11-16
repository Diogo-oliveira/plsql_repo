CREATE OR REPLACE
TRIGGER b_iud_supplies
    BEFORE DELETE OR INSERT OR UPDATE ON supplies
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_supplies := 'SUPPLIES.CODE_SUPPLIES.' || :NEW.id_supplies;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_supplies;
    ELSIF updating
    THEN
        :NEW.code_supplies   := 'SUPPLIES.CODE_SUPPLIES.' || :OLD.id_supplies;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
