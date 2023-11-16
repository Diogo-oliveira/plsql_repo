CREATE OR REPLACE
TRIGGER b_iud_guideline_type
    BEFORE DELETE OR INSERT OR UPDATE ON guideline_type
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_guideline_type := 'GUIDELINE_TYPE.CODE_GUIDELINE_TYPE.' || :NEW.id_guideline_type;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_guideline_type;
    ELSIF updating
    THEN
        :NEW.code_guideline_type := 'GUIDELINE_TYPE.CODE_GUIDELINE_TYPE.' || :OLD.id_guideline_type;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
