CREATE OR REPLACE
TRIGGER b_iud_plant
    BEFORE DELETE OR INSERT OR UPDATE ON plant
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_plant := 'FLOOR.CODE_PLANT.' || :NEW.id_plant;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_plant;
    ELSIF updating
    THEN
        :NEW.code_plant      := 'PLANT.CODE_PLANT.' || :OLD.id_plant;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
