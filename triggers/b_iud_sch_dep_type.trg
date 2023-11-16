CREATE OR REPLACE
TRIGGER b_iud_sch_dep_type
    BEFORE DELETE OR INSERT OR UPDATE ON sch_dep_type
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_dep_type := 'SCH_DEP_TYPE.CODE_DEP_TYPE.' || :NEW.id_sch_dep_type;

        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.dep_type;
    ELSIF updating
    THEN
        :NEW.code_dep_type   := 'SCH_DEP_TYPE.CODE_DEP_TYPE.' || :OLD.id_sch_dep_type;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
