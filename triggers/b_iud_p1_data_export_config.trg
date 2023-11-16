CREATE OR REPLACE
TRIGGER b_iud_p1_data_export_config
    BEFORE DELETE OR INSERT OR UPDATE ON p1_data_export_config
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_data_export_config := 'P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.' || :NEW.id_data_export_config;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_data_export_config;
    ELSIF updating
    THEN
        :NEW.code_data_export_config := 'P1_DATA_EXPORT_CONFIG.CODE_DATA_EXPORT_CONFIG.' || :OLD.id_data_export_config;
    END IF;
END;
/
