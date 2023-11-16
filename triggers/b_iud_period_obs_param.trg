CREATE OR REPLACE
TRIGGER b_iud_period_obs_param
    BEFORE DELETE OR INSERT OR UPDATE ON periodic_observation_param
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_periodic_observation := 'PERIODIC_OBSERVATION_PARAM.CODE_PERIODIC_OBSERVATION.' ||
                                          :NEW.id_periodic_observation_param;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_periodic_observation;
    ELSIF updating
    THEN
        :NEW.code_periodic_observation := 'PERIODIC_OBSERVATION_PARAM.CODE_PERIODIC_OBSERVATION.' ||
                                          :OLD.id_periodic_observation_param;
        :NEW.adw_last_update           := SYSDATE;
    END IF;
END;
/
