CREATE OR REPLACE
TRIGGER b_iud_alert_diagnosis
    BEFORE DELETE OR INSERT OR UPDATE ON alert_diagnosis
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
BEGIN
    IF inserting
       AND :NEW.flg_icd9 = 'N'
    THEN
        :NEW.code_alert_diagnosis := 'ALERT_DIAGNOSIS.CODE_ALERT_DIAGNOSIS.' || :NEW.id_alert_diagnosis;

        :NEW.adw_last_update := SYSDATE;
    ELSIF inserting
    THEN
        :NEW.code_alert_diagnosis := 'DIAGNOSIS.CODE_DIAGNOSIS.' || :NEW.id_diagnosis;
    ELSIF deleting
          AND :OLD.flg_icd9 = 'N'
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_alert_diagnosis;
    ELSIF updating
          AND :OLD.flg_icd9 = 'N'
    THEN
        :NEW.code_alert_diagnosis := 'ALERT_DIAGNOSIS.CODE_ALERT_DIAGNOSIS.' || :OLD.id_alert_diagnosis;
        :NEW.adw_last_update      := SYSDATE;
    END IF;
END;
/



DROP TRIGGER B_IUD_ALERT_DIAGNOSIS;


