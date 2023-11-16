CREATE OR REPLACE
TRIGGER b_iud_iv_fluids_group
    BEFORE DELETE OR INSERT OR UPDATE ON iv_fluids_group
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_iv_fluids_group := 'IV_FLUIDS_GROUP.CODE_IV_FLUIDS_GROUP.' || :NEW.id_iv_fluids_group;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_iv_fluids_group;
    ELSIF updating
    THEN
        :NEW.code_iv_fluids_group := 'IV_FLUIDS_GROUP.CODE_IV_FLUIDS_GROUP.' || :OLD.id_iv_fluids_group;
        :NEW.adw_last_update      := SYSDATE;
    END IF;
END;
/
