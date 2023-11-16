-- CHANGED BY: Telmo
-- CHANGED DATE: 01-06-2009
-- CHANGE REASON: ALERT-694 BED SCHEDULING

CREATE OR REPLACE TRIGGER B_IU_SCH_BED_SLOT_AUDIT 
BEFORE INSERT OR UPDATE ON SCH_BED_SLOT
FOR EACH ROW
DECLARE
BEGIN
    IF pk_utils.str_token(pk_utils.get_client_id, 1, ';') is null
    then
        pk_alertlog.log_error('CLIENT INFO IS NULL');
    ELSE
      IF inserting
      THEN
          :NEW.create_user        := pk_utils.str_token(pk_utils.get_client_id, 1, ';');
          :NEW.create_time        := current_timestamp;
          :NEW.create_institution := pk_utils.str_token(pk_utils.get_client_id, 2, ';');
      ELSIF updating
      THEN
          :NEW.create_user        := nvl(:NEW.create_user, pk_utils.str_token(pk_utils.get_client_id, 1, ';'));
          :NEW.create_time        := nvl(:NEW.create_time, current_timestamp);
          :NEW.create_institution := nvl(:NEW.create_institution, pk_utils.str_token(pk_utils.get_client_id, 2, ';'));
          --
          :NEW.update_user        := pk_utils.str_token(pk_utils.get_client_id, 1, ';');
          :NEW.update_time        := current_timestamp;
          :NEW.update_institution := pk_utils.str_token(pk_utils.get_client_id, 2, ';');
      END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END B_IU_SCH_BED_SLOT_AUDIT;
/
--END