CREATE OR REPLACE
TRIGGER b_iud_ginec_obstet
    BEFORE DELETE OR INSERT OR UPDATE ON ginec_obstet
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_ginec_obstet := 'GINEC_OBSTET.CODE_GINEC_OBSTET.' || :NEW.id_ginec_obstet;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_ginec_obstet;
    ELSIF updating
    THEN
        :NEW.code_ginec_obstet := 'GINEC_OBSTET.CODE_GINEC_OBSTET.' || :OLD.id_ginec_obstet;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
