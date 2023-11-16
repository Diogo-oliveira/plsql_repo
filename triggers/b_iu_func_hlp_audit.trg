CREATE OR REPLACE TRIGGER B_IU_FUNC_HLP_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.FUNCTIONALITY_HELP
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

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

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_FUNC_HLP_AUDIT-'||sqlerrm);
END B_IU_FUNC_HLP_AUDIT;