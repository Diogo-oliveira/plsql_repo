CREATE OR REPLACE
TRIGGER b_iud_floors
    BEFORE DELETE OR INSERT OR UPDATE ON floors
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_floors := 'FLOORS.CODE_FLOORS.' || :NEW.id_floors;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_floors;
    ELSIF updating
    THEN
        :NEW.code_floors     := 'FLOORS.CODE_FLOORS.' || :OLD.id_floors;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
