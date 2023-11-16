CREATE OR REPLACE
TRIGGER b_iud_time_unit
    BEFORE DELETE OR INSERT OR UPDATE ON time_unit
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_time_unit := 'TIME_UNIT.CODE_TIME_UNIT.' || :NEW.id_time_unit;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_time_unit;
    ELSIF updating
    THEN
        :NEW.code_time_unit  := 'TIME_UNIT.CODE_TIME_UNIT.' || :OLD.id_time_unit;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
