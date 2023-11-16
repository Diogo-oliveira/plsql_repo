CREATE OR REPLACE
TRIGGER b_iud_pat_history_type
    BEFORE DELETE OR INSERT OR UPDATE ON pat_history_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_pat_history_type := 'PAT_HISTORY_TYPE.CODE_PAT_HISTORY_TYPE.' || :NEW.id_pat_history_type;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_pat_history_type;
    ELSIF updating
    THEN
        :NEW.code_pat_history_type := 'PAT_HISTORY_TYPE.CODE_PAT_HISTORY_TYPE.' || :OLD.id_pat_history_type;
        :NEW.adw_last_update       := SYSDATE;
    END IF;
END;
/
