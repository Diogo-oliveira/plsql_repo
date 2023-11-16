-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 30-04-2009
-- CHANGE REASON: agenda ORIS

CREATE OR REPLACE TRIGGER B_IU_SCH_CLIPBOARD_AUDIT 
BEFORE INSERT OR UPDATE ON SCH_CLIPBOARD
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
    l_str1 := pk_utils.str_token(pk_utils.get_client_id, 1, ';');
    l_str2 := to_number(pk_utils.str_token(pk_utils.get_client_id, 2, ';'));
    
    IF l_str1 is null
    then
        pk_alertlog.log_error('CLIENT INFO IS NULL');
    ELSE
      IF inserting
      THEN
          :NEW.create_user        := l_str1;
          :NEW.create_time        := current_timestamp;
          :NEW.create_institution := l_str2;
          --
          :NEW.update_user        := NULL;
          :NEW.update_time        := cast(NULL as timestamp with local time zone);
          :NEW.update_institution := NULL;
      ELSIF updating
      THEN
          :NEW.create_user        := :OLD.create_user;
          :NEW.create_time        := :OLD.create_time;
          :NEW.create_institution := :OLD.create_institution;
          --
          :NEW.update_user        := l_str1;
          :NEW.update_time        := current_timestamp;
          :NEW.update_institution := l_str2;
      END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END B_IU_SCH_CLIPBOARD_AUDIT;
/
--END