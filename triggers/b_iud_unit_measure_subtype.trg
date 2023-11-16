CREATE OR REPLACE TRIGGER b_iud_unit_measure_subtype
    BEFORE DELETE OR INSERT OR UPDATE ON unit_measure_subtype
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_unit_measure_subtype := 'UNIT_MEASURE_SUBTYPE.CODE_UNIT_MEASURE_SUBTYPE.' ||
                                          :NEW.id_unit_measure_subtype;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_unit_measure_subtype;
    ELSIF updating
    THEN
        :NEW.code_unit_measure_subtype := 'UNIT_MEASURE_SUBTYPE.CODE_UNIT_MEASURE_SUBTYPE.' ||
                                          :OLD.id_unit_measure_subtype;
    END IF;
END;
