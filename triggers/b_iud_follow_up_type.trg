CREATE OR REPLACE
TRIGGER b_iud_follow_up_type
    BEFORE INSERT OR UPDATE OR DELETE ON follow_up_type
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_follow_up_type := 'FOLLOW_UP_TYPE.CODE_FOLLOW_UP_TYPE.' || :NEW.id_follow_up_type;
        :NEW.code_units          := 'FOLLOW_UP_TYPE.CODE_UNITS.' || :NEW.id_follow_up_type;
        :NEW.adw_last_update     := SYSDATE;

    ELSIF updating
    THEN
        :NEW.code_follow_up_type := 'FOLLOW_UP_TYPE.CODE_FOLLOW_UP_TYPE.' || :NEW.id_follow_up_type;
        :NEW.code_units          := 'FOLLOW_UP_TYPE.CODE_UNITS.' || :NEW.id_follow_up_type;
        :NEW.adw_last_update     := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_follow_up_type
            OR code_translation = :OLD.code_units;
    END IF;
END b_iud_follow_up_type;
/
