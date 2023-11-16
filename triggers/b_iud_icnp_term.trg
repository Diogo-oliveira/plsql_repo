CREATE OR REPLACE
TRIGGER b_iud_icnp_term
    BEFORE DELETE OR INSERT OR UPDATE ON icnp_term
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_term      := 'ICNP_TERM.CODE_TERM.' || :NEW.id_term;
        :NEW.code_help_term := 'ICNP_TERM.CODE_HELP_TERM.' || :NEW.id_term;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_term
            OR code_translation = :OLD.code_term;
    ELSIF updating
    THEN
        :NEW.code_term       := 'ICNP_TERM.CODE_TERM.' || :OLD.id_term;
        :NEW.code_help_term  := 'ICNP_TERM.CODE_HELP_TERM.' || :OLD.id_term;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
