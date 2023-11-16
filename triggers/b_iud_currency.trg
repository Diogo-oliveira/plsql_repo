CREATE OR REPLACE
TRIGGER b_iud_currency
    BEFORE DELETE OR INSERT OR UPDATE ON currency
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_currency := 'CURRENCY.CODE_CURRENCY.' || :NEW.id_currency;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_currency;
    ELSIF updating
    THEN
        :NEW.code_currency   := 'CURRENCY.CODE_CURRENCY.' || :OLD.id_currency;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
