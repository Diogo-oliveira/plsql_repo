CREATE OR REPLACE
TRIGGER b_iud_hidrics_type
    BEFORE DELETE OR INSERT OR UPDATE ON hidrics_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_hidrics_type := 'HIDRICS_TYPE.CODE_HIDRICS_TYPE.' || :NEW.id_hidrics_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_hidrics_type;
    ELSIF updating
    THEN
        :NEW.code_hidrics_type := 'HIDRICS_TYPE.CODE_HIDRICS_TYPE.' || :OLD.id_hidrics_type;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/


--Sofia Mendes (17-11-2009)
drop trigger B_IUD_HIDRICS_TYPE;