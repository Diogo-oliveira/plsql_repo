CREATE OR REPLACE
TRIGGER b_iud_vital_sign_alias

    BEFORE DELETE OR INSERT OR UPDATE ON vital_sign_alias
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_vital_sign_alias := 'VITAL_SIGN_ALIAS.CODE_VITAL_SIGN_ALIAS.' || :NEW.id_vital_sign_alias;

        :NEW.code_abreviation_alias := 'VITAL_SIGN_ALIAS.CODE_ABREVIATION_ALIAS.' || :NEW.id_vital_sign_alias;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_vital_sign_alias
            OR code_translation = :OLD.code_abreviation_alias;
    ELSIF updating
    THEN
        :NEW.code_vital_sign_alias := 'VITAL_SIGN_ALIAS.CODE_VITAL_SIGN_ALIAS.' || :OLD.id_vital_sign_alias;
        :NEW.code_abreviation_alias := 'VITAL_SIGN_ALIAS.CODE_ABREVIATION_ALIAS.' || :OLD.id_vital_sign_alias;
    END IF;
END;
/
