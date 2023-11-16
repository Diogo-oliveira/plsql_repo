CREATE OR REPLACE
TRIGGER b_iud_habit
    BEFORE DELETE OR INSERT OR UPDATE ON alert.habit
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_habit := 'HABIT.CODE_HABIT.' || :NEW.id_habit;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_habit;
    ELSIF updating
    THEN
        :NEW.code_habit := 'HABIT.CODE_HABIT.' || :OLD.id_habit;
    END IF;
END;
/
