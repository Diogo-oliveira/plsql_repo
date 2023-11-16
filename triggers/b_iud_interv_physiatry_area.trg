CREATE OR REPLACE
TRIGGER b_iud_interv_physiatry_area
    BEFORE DELETE OR INSERT OR UPDATE ON interv_physiatry_area
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_interv_physiatry_area := 'INTERV_PHYSIATRY_AREA.CODE_INTERV_PHYSIATRY_AREA.' ||
                                           :NEW.id_interv_physiatry_area;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_interv_physiatry_area;
    ELSIF updating
    THEN
        :NEW.code_interv_physiatry_area := 'INTERV_PHYSIATRY_AREA.CODE_INTERV_PHYSIATRY_AREA.' ||
                                           :OLD.id_interv_physiatry_area;
        :NEW.adw_last_update            := SYSDATE;
    END IF;
END;
/
