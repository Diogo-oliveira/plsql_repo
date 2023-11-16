CREATE OR REPLACE
TRIGGER b_iud_risk_factor_help
    BEFORE DELETE OR INSERT OR UPDATE ON risk_factor_help
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_risk_factor_help       := 'RISK_FACTOR_HELP.CODE_RISK_FACTOR_HELP.' || :NEW.id_risk_factor_help;
        :NEW.code_title_risk_factor_help := 'RISK_FACTOR_HELP.CODE_TITLE_RISK_FACTOR_HELP.' || :NEW.id_risk_factor_help;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_risk_factor_help
            OR code_translation = :OLD.code_title_risk_factor_help;
    ELSIF updating
    THEN
        :NEW.code_risk_factor_help       := 'RISK_FACTOR_HELP.CODE_RISK_FACTOR_HELP.' || :OLD.id_risk_factor_help;
        :NEW.code_title_risk_factor_help := 'RISK_FACTOR_HELP.CODE_TITLE_RISK_FACTOR_HELP.' || :OLD.id_risk_factor_help;
    END IF;
END;
/
