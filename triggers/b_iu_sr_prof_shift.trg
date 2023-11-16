CREATE OR REPLACE
TRIGGER b_iu_sr_prof_shift
    BEFORE INSERT OR UPDATE ON alert.sr_prof_shift
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :NEW.code_sr_prof_shift := 'SR_PROF_SHIFT.CODE_SR_PROF_SHIFT.' || :NEW.id_sr_prof_shift;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sr_prof_shift;
    ELSIF updating
    THEN
        :NEW.code_sr_prof_shift := 'SR_PROF_SHIFT.CODE_SR_PROF_SHIFT.' || :OLD.id_sr_prof_shift;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
