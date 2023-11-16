CREATE OR REPLACE TRIGGER b_iud_discharge_status
    BEFORE DELETE OR INSERT OR UPDATE ON discharge_status
    FOR EACH ROW
BEGIN

    IF inserting
    THEN
        :NEW.code_discharge_status := 'DISCHARGE_STATUS.CODE_DISCHARGE_STATUS.' || :NEW.id_discharge_status;
    ELSIF deleting
    THEN
    
        DELETE FROM translation
         WHERE code_translation = :OLD.code_discharge_status;
    
    ELSIF updating
    THEN
        :NEW.code_discharge_status := 'DISCHARGE_STATUS.CODE_DISCHARGE_STATUS.' || :OLD.id_discharge_status;
    END IF;

END b_iud_discharge_status;
