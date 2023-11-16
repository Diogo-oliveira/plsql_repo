CREATE OR REPLACE
TRIGGER b_uid_ingredient
    BEFORE DELETE OR INSERT OR UPDATE ON alert.ingredient
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_ingredient := 'INGREDIENT.CODE_INGREDIENT.' || :NEW.id_ingredient;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_ingredient;
    ELSIF updating
    THEN
        :NEW.code_ingredient := 'INGREDIENT.CODE_INGREDIENT.' || :OLD.id_ingredient;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
