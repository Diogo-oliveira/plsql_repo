CREATE OR REPLACE TRIGGER b_iud_market
    BEFORE DELETE OR INSERT OR UPDATE ON market
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_market     := 'MARKET.CODE_MARKET.' || :NEW.id_market;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_market;

    ELSIF updating
    THEN
        :NEW.code_market     := 'MARKET.CODE_MARKET.' || :OLD.id_market;
    END IF;
END;

DROP TRIGGER B_IUD_MARKET;