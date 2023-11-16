CREATE OR REPLACE
TRIGGER b_iu_body_side
    BEFORE DELETE OR INSERT OR UPDATE ON body_side
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_body_side := 'BODY_SIDE.CODE_BODY_SIDE.' || :NEW.id_body_side;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_body_side;
    ELSIF updating
    THEN
        :NEW.code_body_side  := 'BODY_SIDE.CODE_BODY_SIDE.' || :OLD.id_body_side;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
