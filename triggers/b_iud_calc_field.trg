CREATE OR REPLACE TRIGGER b_iud_calc_field
    BEFORE INSERT OR UPDATE OR DELETE ON calc_field
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.code_calc_field := 'CALC_FIELD.CODE_CALC_FIELD.' || :new.id_calc_field;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE t.code_translation = :old.code_calc_field
           AND t.code_translation LIKE 'CALC\_FIELD.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :new.code_calc_field := 'CALC_FIELD.CODE_CALC_FIELD.' || :old.id_calc_field;
    END IF;
END b_iud_calc_field;
/
