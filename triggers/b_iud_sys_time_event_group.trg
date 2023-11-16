CREATE OR REPLACE
TRIGGER b_iud_sys_time_event_group
    BEFORE DELETE OR INSERT OR UPDATE ON sys_time_event_group
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_time_event_group := 'TIME_EVENT_GROUP.CODE_TIME_EVENT_GROUP.' || :NEW.id_time_event_group;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_time_event_group;
    ELSIF updating
    THEN
        :NEW.code_time_event_group := 'TIME_EVENT_GROUP.CODE_TIME_EVENT_GROUP.' || :OLD.id_time_event_group;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/
