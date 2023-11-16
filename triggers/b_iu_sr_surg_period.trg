CREATE OR REPLACE
TRIGGER b_iu_sr_surg_period
    BEFORE INSERT OR UPDATE OF id_surg_period, code_surg_period, rank ON alert.sr_surg_period
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_surg_period := 'SR_SURG_PERIOD.CODE_SURG_PERIOD.' || :NEW.id_surg_period;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_surg_period;
    ELSIF updating
    THEN
        :NEW.code_surg_period := 'SR_SURG_PERIOD.CODE_SURG_PERIOD.' || :OLD.id_surg_period;
        :NEW.adw_last_update  := SYSDATE;

    END IF;
END;
/
