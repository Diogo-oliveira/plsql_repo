CREATE OR REPLACE
TRIGGER
b_iud_occupation
    BEFORE DELETE OR INSERT OR UPDATE ON OCCUPATION_OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_occupation := 'OCCUPATION.CODE_OCCUPATION.' || :NEW.id_occupation;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_occupation;
    ELSIF updating
    THEN
        :NEW.code_occupation := 'OCCUPATION.CODE_OCCUPATION.' || :OLD.id_occupation;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;

/


drop trigger B_IUD_OCCUPATION;