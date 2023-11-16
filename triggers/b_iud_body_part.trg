CREATE OR REPLACE
TRIGGER b_iud_body_part
    BEFORE DELETE OR INSERT OR UPDATE ON body_part
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_body_part := 'BODY_PART.CODE_BODY_PART.' || :NEW.id_body_part;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_body_part;
    ELSIF updating
    THEN
        :NEW.code_body_part  := 'BODY_PART.CODE_BODY_PART.' || :OLD.id_body_part;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
