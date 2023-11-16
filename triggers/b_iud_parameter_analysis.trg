CREATE OR REPLACE
TRIGGER b_iud_parameter_analysis
    BEFORE DELETE OR INSERT OR UPDATE ON parameter_analysis_20071023
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_parameter_analysis := 'PARAMETER_ANALYSIS.CODE_PARAMETER_ANALYSIS.' || :NEW.id_parameter_analysis;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_parameter_analysis;
    ELSIF updating
    THEN
        :NEW.code_parameter_analysis := 'PARAMETER_ANALYSIS.CODE_PARAMETER_ANALYSIS.' || :OLD.id_parameter_analysis;
        :NEW.adw_last_update         := SYSDATE;
    END IF;
END;
/

drop trigger b_iud_parameter_analysis;