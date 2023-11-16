CREATE OR REPLACE
TRIGGER b_iud_triage_considerations
    BEFORE DELETE OR INSERT OR UPDATE ON triage_considerations
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_triage_considerations := 'TRIAGE_CONSIDERATIONS.CODE_TRIAGE_CONSIDERATIONS.' ||
                                           :NEW.id_triage_considerations;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_triage_considerations;
    ELSIF updating
    THEN
        :NEW.code_triage_considerations := 'TRIAGE_CONSIDERATIONS.CODE_TRIAGE_CONSIDERATIONS.' ||
                                           :OLD.id_triage_considerations;
        :NEW.adw_last_update            := SYSDATE;
    END IF;
END;
/
