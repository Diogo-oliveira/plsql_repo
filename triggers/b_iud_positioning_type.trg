CREATE OR REPLACE
TRIGGER b_iud_positioning_type
    BEFORE DELETE OR INSERT OR UPDATE ON positioning_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_positioning_type := 'POSITIONING_TYPE.CODE_POSITIONING_TYPE.' || :NEW.id_positioning_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_positioning_type;
    ELSIF updating
    THEN
        :NEW.code_positioning_type := 'POSITIONING_TYPE.CODE_POSITIONING_TYPE.' || :OLD.id_positioning_type;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/
