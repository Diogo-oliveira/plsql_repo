CREATE OR REPLACE
TRIGGER b_iud_graffar_criteria
    BEFORE DELETE OR INSERT OR UPDATE ON graffar_criteria
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_graffar_criteria := 'GRAFFAR_CRITERIA.CODE_GRAFFAR_CRITERIA.' || :NEW.id_graffar_criteria;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_graffar_criteria;

    ELSIF updating
    THEN
        :NEW.code_graffar_criteria := 'GRAFFAR_CRITERIA.CODE_GRAFFAR_CRITERIA.' || :OLD.id_graffar_criteria;
        :NEW.adw_last_update       := SYSDATE;

    END IF;
END;
/
