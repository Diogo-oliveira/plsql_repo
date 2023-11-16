CREATE OR REPLACE
TRIGGER b_iud_icnp_composition
    BEFORE DELETE OR INSERT OR UPDATE ON icnp_composition
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_icnp_composition := 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || :NEW.id_composition;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_icnp_composition;
    ELSIF updating
    THEN
        :NEW.code_icnp_composition := 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || :OLD.id_composition;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/
