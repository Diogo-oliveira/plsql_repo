CREATE OR REPLACE
TRIGGER b_iu_sr_posit
    BEFORE INSERT OR UPDATE OF id_sr_parent, code_sr_posit, rank, flg_exclusive, flg_available, id_institution ON alert.sr_posit
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sr_posit := 'SR_POSIT.CODE_SR_POSIT.' || :NEW.id_sr_posit;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sr_posit;

    ELSIF updating
    THEN
        :NEW.code_sr_posit   := 'SR_POSIT.CODE_SR_POSIT.' || :OLD.id_sr_posit;
        :NEW.adw_last_update := SYSDATE;

    END IF;
END;
/


-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 09/12/2009 
-- CHANGE REASON: [ALERT-61585] 
drop trigger ALERT.b_iu_sr_posit;

--CHANGE END: Filipe Silva