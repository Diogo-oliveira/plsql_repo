CREATE OR REPLACE
TRIGGER b_iud_hemo_type
    BEFORE INSERT OR UPDATE ON alert.hemo_type
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_hemo_type := 'HEMO_TYPE.CODE_HEMO_TYPE.' || :NEW.id_hemo_type;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_hemo_type;
    ELSIF updating
    THEN
        :NEW.code_hemo_type := 'HEMO_TYPE.CODE_HEMO_TYPE.' || :OLD.id_hemo_type;
    END IF;
    :NEW.adw_last_update := SYSDATE;
END;
/
