CREATE OR REPLACE
TRIGGER b_iud_vital_sign
    BEFORE DELETE OR INSERT OR UPDATE ON vital_sign
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :new.code_vital_sign    := 'VITAL_SIGN.CODE_VITAL_SIGN.' || :new.id_vital_sign;
        :new.code_measure_unit  := 'VITAL_SIGN.CODE_MEASURE_UNIT.' || :new.id_vital_sign;
        :new.code_vs_short_desc := 'VITAL_SIGN.CODE_VS_SHORT_DESC.' || :new.id_vital_sign;
    
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :old.code_vital_sign
            OR code_translation = :old.code_measure_unit
            OR code_translation = :old.code_vs_short_desc;
    
    ELSIF updating
    THEN
        :new.code_vital_sign    := 'VITAL_SIGN.CODE_VITAL_SIGN.' || :old.id_vital_sign;
        :new.code_measure_unit  := 'VITAL_SIGN.CODE_MEASURE_UNIT.' || :old.id_vital_sign;
        :new.code_vs_short_desc := 'VITAL_SIGN.CODE_VS_SHORT_DESC.' || :old.id_vital_sign;
    
    END IF;

END;
/
