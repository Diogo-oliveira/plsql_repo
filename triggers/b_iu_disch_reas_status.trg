CREATE OR REPLACE TRIGGER b_iu_disch_reas_status
    BEFORE INSERT OR UPDATE ON disch_reas_status
    FOR EACH ROW
DECLARE
    -- local variables here
BEGIN
    IF :new.ID_DISCHARGE_REASON is not null and :new.SCREEN_NAME is not null
    THEN
        raise_application_error(-20400,
                                'This record cannot be inserted because only one of the following columns "ID_DISCHARGE_REASON" and "SCREEN_NAME" can be filled.');
    END IF;
    
    IF :new.ID_DISCHARGE_REASON is null and :new.SCREEN_NAME is null
    THEN
        raise_application_error(-20401,
                                'This record cannot be inserted because one of the following columns "ID_DISCHARGE_REASON" and "SCREEN_NAME" must be filled.');
    END IF;
    
    IF (updating) AND (:old.id_institution = 0 OR :new.id_institution = 0)
    THEN
        raise_application_error(-20402,
                                'Default configurations should not be changed through local configurations.');
    END IF;
    
END b_iu_disch_reas_status;
/
