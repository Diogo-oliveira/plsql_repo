CREATE OR REPLACE
TRIGGER b_iud_period_obs_desc
    BEFORE DELETE OR INSERT OR UPDATE ON periodic_observation_desc
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_periodic_observation_desc := 'PERIODIC_OBSERVATION_DESC.CODE_PERIODIC_OBSERVATION_DESC.' ||
                                               :NEW.id_periodic_observation_desc;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_periodic_observation_desc;
    ELSIF updating
    THEN
        :NEW.code_periodic_observation_desc := 'PERIODIC_OBSERVATION_DESC.CODE_PERIODIC_OBSERVATION_DESC.' ||
                                               :OLD.id_periodic_observation_desc;
        :NEW.adw_last_update                := SYSDATE;
    END IF;
END;
/
