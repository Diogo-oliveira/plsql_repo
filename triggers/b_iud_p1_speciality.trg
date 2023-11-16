CREATE OR REPLACE
TRIGGER b_iud_p1_speciality
    BEFORE DELETE OR INSERT OR UPDATE ON p1_speciality
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_speciality := 'P1_SPECIALITY.CODE_SPECIALITY.' || :NEW.id_speciality;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_speciality;
    ELSIF updating
    THEN
        :NEW.code_speciality := 'P1_SPECIALITY.CODE_SPECIALITY.' || :OLD.id_speciality;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
