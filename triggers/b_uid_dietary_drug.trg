CREATE OR REPLACE
TRIGGER b_uid_dietary_drug
    BEFORE DELETE OR INSERT OR UPDATE ON alert.dietary_drug
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_dietary_drug := 'DIETARY_DRUG.CODE_DIETARY_DRUG.' || :NEW.id_dietary_drug;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_dietary_drug;
    ELSIF updating
    THEN
        :NEW.code_dietary_drug := 'DIETARY_DRUG.CODE_DIETARY_DRUG.' || :OLD.id_dietary_drug;
        :NEW.adw_last_update   := SYSDATE;
    END IF;

END b_uid_dietary_drug;
/
