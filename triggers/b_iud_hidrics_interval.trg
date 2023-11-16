CREATE OR REPLACE
TRIGGER b_iud_hidrics_interval
    BEFORE DELETE OR INSERT OR UPDATE ON hidrics_interval
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_hidrics_interval := 'HIDRICS_INTERVAL.CODE_HIDRICS_INTERVAL.' || :NEW.id_hidrics_interval;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_hidrics_interval;
    ELSIF updating
    THEN
        :NEW.code_hidrics_interval := 'HIDRICS_INTERVAL.CODE_HIDRICS_INTERVAL.' || :OLD.id_hidrics_interval;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/


--Sofia Mendes (17-11-2009)
drop trigger B_IUD_HIDRICS_INTERVAL;