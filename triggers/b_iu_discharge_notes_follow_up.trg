CREATE OR REPLACE TRIGGER B_IU_DISCHARGE_NOTES_FOLLOW_UP
BEFORE INSERT OR UPDATE
ON DISCHARGE_NOTES_FOLLOW_UP
FOR EACH ROW
DECLARE
    l_id_discharge_notes discharge_notes.id_discharge_notes%TYPE;
    l_id_follow_up_with  discharge_notes_follow_up.id_follow_up_with%TYPE;
    l_flg_type           follow_up_entity.flg_type%TYPE;
BEGIN
    -- Check if ID_DISCHARGE_NOTES exists
    SELECT dn.id_discharge_notes
      INTO l_id_discharge_notes
      FROM discharge_notes dn
     WHERE dn.id_discharge_notes = :NEW.id_discharge_notes;

    SELECT fue.flg_type
      INTO l_flg_type
      FROM follow_up_entity fue
     WHERE fue.id_follow_up_entity = :NEW.id_follow_up_entity;

    IF l_flg_type = 'OC'
    THEN
        -- If it's an on-call physician, just check if there's an existing professional
        -- with the corresponding ID, there's no need to check if the professional has 
        -- an active on-call shift.
        SELECT p.id_professional
          INTO l_id_follow_up_with
          FROM professional p
         WHERE p.id_professional = :NEW.id_follow_up_with;
    
    ELSIF l_flg_type = 'PH'
    THEN
        -- External professionals
        SELECT p.id_professional
          INTO l_id_follow_up_with
          FROM professional p
         WHERE p.id_professional = :NEW.id_follow_up_with;
    
    ELSIF l_flg_type = 'CL'
    THEN
        -- External institutions (clinics)
        SELECT i.id_institution
          INTO l_id_follow_up_with
          FROM institution i
         WHERE i.id_institution = :NEW.id_follow_up_with;
    
    ELSIF l_flg_type = 'O'
    THEN
        -- Doesn't need to be checked. Follow-up entity specified with free text.
        NULL;
    ELSE
        raise_application_error(-20001, 'Invalid value for FLG_FOLLOW_UP_WITH.');
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20001, 'Foreign key not available on referred table. ID = ' || :NEW.id_follow_up_with);
END;
/
