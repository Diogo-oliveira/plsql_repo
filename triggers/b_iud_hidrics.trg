CREATE OR REPLACE
TRIGGER b_iud_hidrics
    BEFORE DELETE OR INSERT OR UPDATE ON hidrics
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_hidrics := 'HIDRICS.CODE_HIDRICS.' || :NEW.id_hidrics;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_hidrics;
    ELSIF updating
    THEN
        :NEW.code_hidrics    := 'HIDRICS.CODE_HIDRICS.' || :OLD.id_hidrics;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/

--Sofia Mendes (17-11-2009)
drop trigger B_IUD_HIDRICS;