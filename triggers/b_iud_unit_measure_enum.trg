CREATE OR REPLACE
TRIGGER b_iud_unit_measure_enum
    BEFORE DELETE OR INSERT OR UPDATE ON unit_measure_enum
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_unit_measure_enum1 := 'UNIT_MEASURE_ENUM.CODE_UNIT_MEASURE_ENUM1.' || :NEW.id_unit_measure_enum;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_unit_measure_enum1;
    ELSIF updating
    THEN
        :NEW.code_unit_measure_enum1 := 'UNIT_MEASURE_ENUM.CODE_UNIT_MEASURE_ENUM1.' || :OLD.id_unit_measure_enum;
        :NEW.adw_last_update         := SYSDATE;
    END IF;
END;
/
