CREATE OR REPLACE
TRIGGER b_iu_sr_surgery_time
    BEFORE INSERT OR UPDATE ON alert.sr_surgery_time
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sr_surgery_time := 'SR_SURGERY_TIME.CODE_SR_SURGERY_TIME.' || :NEW.id_sr_surgery_time;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sr_surgery_time;
    ELSIF updating
    THEN
        :NEW.code_sr_surgery_time := 'SR_SURGERY_TIME.CODE_SR_SURGERY_TIME.' || :OLD.id_sr_surgery_time;
        :NEW.adw_last_update      := SYSDATE;
    END IF;
END;
/
