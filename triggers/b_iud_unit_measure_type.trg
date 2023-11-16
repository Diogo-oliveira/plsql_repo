CREATE OR REPLACE
TRIGGER b_iud_unit_measure_type
    BEFORE DELETE OR INSERT OR UPDATE ON unit_measure_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_unit_measure_type := 'UNIT_MEASURE_TYPE.CODE_UNIT_MEASURE_TYPE.' || :NEW.id_unit_measure_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_unit_measure_type;
    ELSIF updating
    THEN
        :NEW.code_unit_measure_type := 'UNIT_MEASURE_TYPE.CODE_UNIT_MEASURE_TYPE.' || :OLD.id_unit_measure_type;
        :NEW.adw_last_update        := SYSDATE;
    END IF;
END;
/
