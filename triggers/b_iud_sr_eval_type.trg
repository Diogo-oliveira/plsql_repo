CREATE OR REPLACE
TRIGGER b_iud_sr_eval_type
    BEFORE DELETE OR INSERT OR UPDATE ON sr_eval_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sr_eval_type := 'SR_EVAL_TYPE.CODE_SR_EVAL_TYPE.' || :NEW.id_sr_eval_type;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sr_eval_type;

    ELSIF updating
    THEN
        :NEW.code_sr_eval_type := 'SR_EVAL_TYPE.CODE_SR_EVAL_TYPE.' || :OLD.id_sr_eval_type;

    END IF;
END;
/
