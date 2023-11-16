CREATE OR REPLACE TRIGGER b_iud_health_program
    BEFORE DELETE OR INSERT OR UPDATE ON health_program
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_health_program    := 'HEALTH_PROGRAM.CODE_HEALTH_PROGRAM.' || :NEW.id_health_program;
        :NEW.dt_health_program_tstz := current_timestamp;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_health_program
           AND code_translation LIKE 'HEALTH\_PROGRAM.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :NEW.code_health_program := 'HEALTH_PROGRAM.CODE_HEALTH_PROGRAM.' || :OLD.id_health_program;
    END IF;
END;
/
