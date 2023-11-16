CREATE OR REPLACE
TRIGGER b_iu_sr_equip
    BEFORE INSERT OR UPDATE OF id_sr_equip ON alert.sr_equip
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_equip := 'SR_EQUIP.CODE_EQUIP.' || :NEW.id_sr_equip;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_equip;

    ELSIF updating
    THEN
        :NEW.code_equip      := 'SR_EQUIP.CODE_EQUIP.' || :OLD.id_sr_equip;
        :NEW.adw_last_update := SYSDATE;

    END IF;
END;
/
