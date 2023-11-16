CREATE OR REPLACE
TRIGGER b_iud_sch_event_abrv
    BEFORE DELETE OR INSERT OR UPDATE ON sch_event
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sch_event_abrv := 'SCH_EVENT.CODE_SCH_EVENT_ABRV.' || :NEW.id_sch_event;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_sch_event_abrv;
    ELSIF updating
    THEN
        :NEW.code_sch_event_abrv := 'SCH_EVENT.CODE_SCH_EVENT_ABRV.' || :OLD.id_sch_event;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
