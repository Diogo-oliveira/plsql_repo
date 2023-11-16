CREATE OR REPLACE
TRIGGER b_iud_graffar_crit_value
    BEFORE DELETE OR INSERT OR UPDATE ON graffar_crit_value
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_graffar_crit_value := 'GRAFFAR_CRIT_VALUE.CODE_GRAFFAR_CRIT_VALUE.' || :NEW.id_graffar_crit_value;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_graffar_crit_value;

    ELSIF updating
    THEN
        :NEW.code_graffar_crit_value := 'GRAFFAR_CRIT_VALUE.CODE_GRAFFAR_CRIT_VALUE.' || :OLD.id_graffar_crit_value;
        :NEW.adw_last_update         := SYSDATE;

    END IF;
END;
/
