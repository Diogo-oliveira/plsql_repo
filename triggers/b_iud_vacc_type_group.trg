CREATE OR REPLACE
TRIGGER b_iud_vacc_type_group
    BEFORE DELETE OR INSERT OR UPDATE ON vacc_type_group
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_vacc_type_group := 'VACC_TYPE_GROUP.CODE_VACC_TYPE_GROUP.' || :NEW.id_vacc_type_group;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_vacc_type_group;

    ELSIF updating
    THEN
        :NEW.code_vacc_type_group := 'VACC_TYPE_GROUP.CODE_VACC_TYPE_GROUP.' || :OLD.id_vacc_type_group;
    END IF;
END;
/
