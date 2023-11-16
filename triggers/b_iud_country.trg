CREATE OR REPLACE
TRIGGER b_iud_country
    BEFORE DELETE OR INSERT OR UPDATE ON country
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_country     := 'COUNTRY.CODE_COUNTRY.' || :NEW.id_country;
        :NEW.code_nationality := 'COUNTRY.CODE_NATIONALITY.' || :NEW.id_country;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_country
            OR code_translation = :OLD.code_nationality;

    ELSIF updating
    THEN
        :NEW.code_country     := 'COUNTRY.CODE_COUNTRY.' || :OLD.id_country;
        :NEW.code_nationality := 'COUNTRY.CODE_NATIONALITY.' || :OLD.id_country;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
