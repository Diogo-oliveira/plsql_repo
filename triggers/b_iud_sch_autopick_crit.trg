-- CHANGED BY: Telmo
-- CHANGED DATE: 01-06-2009
-- CHANGE REASON: ALERT-694 BED SCHEDULING
CREATE OR REPLACE TRIGGER b_iud_sch_autopick_crit
    BEFORE DELETE OR INSERT OR UPDATE ON sch_autopick_crit
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_criteria := 'SCH_AUTOPICK_CRIT.CODE_CRITERIA.' || :NEW.id_criteria;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_criteria;
    ELSIF updating
    THEN
        :NEW.code_criteria := 'SCH_AUTOPICK_CRIT.CODE_CRITERIA.' || :OLD.id_criteria;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/

--END