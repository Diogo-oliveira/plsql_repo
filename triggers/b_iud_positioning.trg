CREATE OR REPLACE
TRIGGER b_iud_positioning
    BEFORE DELETE OR INSERT OR UPDATE ON positioning
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_positioning := 'POSITIONING.CODE_POSITIONING.' || :NEW.id_positioning;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_positioning;
    ELSIF updating
    THEN
        :NEW.code_positioning := 'POSITIONING.CODE_POSITIONING.' || :OLD.id_positioning;
        :NEW.adw_last_update  := SYSDATE;
    END IF;
END;
/
