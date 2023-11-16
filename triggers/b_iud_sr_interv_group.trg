CREATE OR REPLACE
TRIGGER b_iud_sr_interv_group
    BEFORE DELETE OR INSERT OR UPDATE OF id_sr_interv_group ON alert.sr_interv_group
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sr_interv_group := 'SR_INTERV_GROUP.CODE_SR_INTERV_GROUP.' || :NEW.id_sr_interv_group;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sr_interv_group;

    ELSIF updating
    THEN
        :NEW.code_sr_interv_group := 'SR_INTERV_GROUP.CODE_SR_INTERV_GROUP.' || :OLD.id_sr_interv_group;
        :NEW.adw_last_update      := SYSDATE;
    END IF;
END;
/
