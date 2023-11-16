CREATE OR REPLACE
TRIGGER b_iud_location_tax
    BEFORE INSERT OR UPDATE OR DELETE ON location_tax
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_location_tax := 'LOCATION_TAX.CODE_LOCATION_TAX.' || :NEW.id_location_tax;
        :NEW.code_desc_label   := 'LOCATION_TAX.CODE_DESC_LABEL.' || :NEW.id_location_tax;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_desc_label
            OR code_translation = :OLD.code_location_tax;
    ELSIF updating
    THEN
        :NEW.code_location_tax := 'LOCATION_TAX.CODE_LOCATION_TAX.' || :OLD.id_location_tax;
        :NEW.code_desc_label   := 'LOCATION_TAX.CODE_DESC_LABEL.' || :OLD.id_location_tax;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END b_iud_location_tax;
/
