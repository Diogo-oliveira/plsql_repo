CREATE OR REPLACE TRIGGER b_iud_analysis_parameter
    BEFORE DELETE OR INSERT OR UPDATE ON analysis_parameter
    FOR EACH ROW

    -- PL/SQL Block
BEGIN
    IF inserting
    THEN
        :new.code_analysis_parameter := 'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' || :new.id_analysis_parameter;
    
        :new.adw_last_update := SYSDATE;
    
    ELSIF deleting
    THEN
        pk_translation.delete_code_translation(table_varchar(:old.code_analysis_parameter));
    ELSIF updating
    THEN
        :new.code_analysis_parameter := 'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' || :old.id_analysis_parameter;
        :new.adw_last_update         := SYSDATE;
    
    END IF;
END;
/
