CREATE OR REPLACE
TRIGGER b_iud_material
    BEFORE DELETE OR INSERT OR UPDATE ON material
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_material := 'MATERIAL.CODE_MATERIAL.' || :NEW.id_material;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_material;
    ELSIF updating
    THEN
        :NEW.code_material   := 'MATERIAL.CODE_MATERIAL.' || :OLD.id_material;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
