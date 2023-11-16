CREATE OR REPLACE
TRIGGER b_iud_drug_posologia
    BEFORE DELETE OR INSERT OR UPDATE ON drug_posologia
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_drug_posologia := 'DRUG_POSOLOGIA.CODE_DRUG_POSOLOGIA.' || :NEW.id_drug_posologia;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_drug_posologia;
    ELSIF updating
    THEN
        :NEW.code_drug_posologia := 'DRUG_POSOLOGIA.CODE_DRUG_POSOLOGIA.' || :OLD.id_drug_posologia;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
