CREATE OR REPLACE
TRIGGER b_iud_scales
    BEFORE DELETE OR INSERT OR UPDATE ON scales
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_scales      := 'SCALES.CODE_SCALES.' || :NEW.id_scales;
        :NEW.code_scale_score := 'SCALES.CODE_SCALE_SCORE.' || :NEW.id_scales;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_scales;
    ELSIF updating
    THEN
        :NEW.code_scales      := 'SCALES.CODE_SCALES.' || :OLD.id_scales;
        :NEW.code_scale_score := 'SCALES.CODE_SCALE_SCORE.' || :OLD.id_scales;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
