CREATE OR REPLACE
TRIGGER b_iud_ebm
    BEFORE DELETE OR INSERT OR UPDATE ON ebm
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_ebm := 'EBM.CODE_EBM.' || :NEW.id_ebm;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_ebm;
    ELSIF updating
    THEN
        :NEW.code_ebm        := 'EBM.CODE_EBM.' || :OLD.id_ebm;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
