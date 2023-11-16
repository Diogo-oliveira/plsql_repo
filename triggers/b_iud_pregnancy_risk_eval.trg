CREATE OR REPLACE
TRIGGER b_iud_pregnancy_risk_eval
    BEFORE DELETE OR INSERT OR UPDATE ON pregnancy_risk_eval
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_pregnancy_risk_eval := 'PREGNANCY_RISK_EVAL.CODE_PREGNANCY_RISK_EVAL.' || :NEW.id_pregnancy_risk_eval;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_pregnancy_risk_eval;
    ELSIF updating
    THEN
        :NEW.code_pregnancy_risk_eval := 'PREGNANCY_RISK_EVAL.CODE_PREGNANCY_RISK_EVAL.' || :OLD.id_pregnancy_risk_eval;
    END IF;
END;
/
