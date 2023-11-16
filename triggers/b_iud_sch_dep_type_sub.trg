CREATE OR REPLACE
TRIGGER b_iud_sch_dep_type_sub
    BEFORE DELETE OR INSERT OR UPDATE ON sch_dep_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_sched_subtype := 'SCH_DEP_TYPE.CODE_SCHED_SUBTYPE.' || :NEW.id_sch_dep_type;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.dep_type;
    ELSIF updating
    THEN
        :NEW.code_sched_subtype := 'SCH_DEP_TYPE.CODE_SCHED_SUBTYPE.' || :OLD.id_sch_dep_type;
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/
