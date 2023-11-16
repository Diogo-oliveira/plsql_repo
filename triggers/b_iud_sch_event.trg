CREATE OR REPLACE
TRIGGER b_iud_sch_event
    BEFORE DELETE OR INSERT OR UPDATE ON sch_event
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sch_event := 'SCH_EVENT.CODE_SCH_EVENT.' || :NEW.id_sch_event;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sch_event;
    ELSIF updating
    THEN
        :NEW.code_sch_event  := 'SCH_EVENT.CODE_SCH_EVENT.' || :OLD.id_sch_event;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
