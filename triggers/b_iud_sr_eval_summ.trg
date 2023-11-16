CREATE OR REPLACE
TRIGGER b_iud_sr_eval_summ
    BEFORE DELETE OR INSERT OR UPDATE ON sr_eval_summ
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sr_eval_summ := 'SR_EVAL_SUMM.CODE_SR_EVAL_SUMM.' || :NEW.id_sr_eval_summ;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sr_eval_summ;

    ELSIF updating
    THEN
        :NEW.code_sr_eval_summ := 'SR_EVAL_SUMM.CODE_SR_EVAL_SUMM.' || :OLD.id_sr_eval_summ;

    END IF;
END;
/
