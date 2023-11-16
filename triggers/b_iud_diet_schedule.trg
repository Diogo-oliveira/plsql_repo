CREATE OR REPLACE
TRIGGER b_iud_diet_schedule
    BEFORE DELETE OR INSERT OR UPDATE ON diet_schedule
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_diet_schedule := 'DIET_SCHEDULE.CODE_DIET_SCHEDULE.' || :NEW.id_diet_schedule;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_diet_schedule;
    ELSIF updating
    THEN
        :NEW.code_diet_schedule := 'DIET_SCHEDULE.CODE_DIET_SCHEDULE.' || :OLD.id_diet_schedule;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
