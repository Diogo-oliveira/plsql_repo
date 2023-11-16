CREATE OR REPLACE
TRIGGER b_iud_diet
    BEFORE DELETE OR INSERT OR UPDATE ON diet
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_diet := 'DIET.CODE_DIET.' || :NEW.id_diet;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_diet;
    ELSIF updating
    THEN
        :NEW.code_diet       := 'DIET.CODE_DIET.' || :OLD.id_diet;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
