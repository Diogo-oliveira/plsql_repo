CREATE OR REPLACE
TRIGGER b_iud_diagnosis
    BEFORE DELETE OR INSERT OR UPDATE ON diagnosis
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_diagnosis := 'DIAGNOSIS.CODE_DIAGNOSIS.' || :NEW.id_diagnosis;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_diagnosis;
    ELSIF updating
    THEN
        :NEW.code_diagnosis  := 'DIAGNOSIS.CODE_DIAGNOSIS.' || :OLD.id_diagnosis;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/



DROP TRIGGER B_IUD_DIAGNOSIS;
