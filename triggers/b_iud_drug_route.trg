CREATE OR REPLACE
TRIGGER b_iud_drug_route
    BEFORE DELETE OR INSERT OR UPDATE ON drug_route
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_drug_route := 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || :NEW.id_drug_route;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_route;
    ELSIF updating
    THEN
        :NEW.code_drug_route := 'DRUG_ROUTE.CODE_DRUG_ROUTE.' || :OLD.id_drug_route;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
