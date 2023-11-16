CREATE OR REPLACE
TRIGGER b_iud_icnp_axis
    BEFORE DELETE OR INSERT OR UPDATE ON icnp_axis
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_axis      := 'ICNP_AXIS.CODE_AXIS.' || :NEW.id_axis;
        :NEW.code_help_axis := 'ICNP_AXIS.CODE_HELP_AXIS.' || :NEW.id_axis;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_axis
            OR code_translation = :OLD.code_help_axis;
    ELSIF updating
    THEN
        :NEW.code_axis       := 'ICNP_AXIS.CODE_AXIS.' || :OLD.id_axis;
        :NEW.code_help_axis  := 'ICNP_AXIS.CODE_HELP_AXIS.' || :OLD.id_axis;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
