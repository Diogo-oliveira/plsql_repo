CREATE OR REPLACE
TRIGGER b_iud_rep_destination
    BEFORE DELETE OR INSERT OR UPDATE OF id_rep_destination ON alert.rep_destination
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_rep_destination := 'REP_DESTINATION.CODE_REP_DESTINATION.' || :NEW.id_rep_destination;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_rep_destination;

    ELSIF updating
    THEN
        :NEW.code_rep_destination := 'REP_DESTINATION.CODE_REP_DESTINATION.' || :OLD.id_rep_destination;

    END IF;
END;
/
