CREATE OR REPLACE
TRIGGER b_iud_unit_measure
    BEFORE DELETE OR INSERT OR UPDATE ON unit_measure
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_unit_measure      := 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || :NEW.id_unit_measure;
        :NEW.code_unit_measure_abrv := 'UNIT_MEASURE.CODE_UNIT_MEASURE_ABRV.' || :NEW.id_unit_measure;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_unit_measure
            OR code_translation = :OLD.code_unit_measure_abrv;
    ELSIF updating
    THEN
        :NEW.code_unit_measure      := 'UNIT_MEASURE.CODE_UNIT_MEASURE.' || :OLD.id_unit_measure;
        :NEW.code_unit_measure_abrv := 'UNIT_MEASURE.CODE_UNIT_MEASURE_ABRV.' || :OLD.id_unit_measure;
        :NEW.adw_last_update        := SYSDATE;
    END IF;
END;
/
