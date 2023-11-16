CREATE OR REPLACE
TRIGGER b_iud_family_relationship
    BEFORE DELETE OR INSERT OR UPDATE ON family_relationship
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_family_relationship := 'FAMILY_RELATIONSHIP.CODE_FAMILY_RELATIONSHIP.' || :NEW.id_family_relationship;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_family_relationship;
    ELSIF updating
    THEN
        :NEW.code_family_relationship := 'FAMILY_RELATIONSHIP.CODE_FAMILY_RELATIONSHIP.' || :OLD.id_family_relationship;
        :NEW.adw_last_update          := SYSDATE;
    END IF;
END;
/
