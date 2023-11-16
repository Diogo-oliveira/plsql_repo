CREATE OR REPLACE TRIGGER b_iud_bed
    BEFORE DELETE OR INSERT OR UPDATE ON bed
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        IF :NEW.flg_type = 'P'
        THEN
            :NEW.code_bed := 'BED.CODE_BED.' || :NEW.id_bed;
        END IF;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_bed;
    ELSIF updating
    THEN
        :NEW.code_bed := 'BED.CODE_BED.' || :OLD.id_bed;
    END IF;
END;
/
