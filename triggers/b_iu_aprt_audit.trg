CREATE OR REPLACE TRIGGER B_IU_APRT_AUDIT
BEFORE INSERT OR UPDATE ON APPROVAL_REQUEST
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 NUMBER(24);
BEGIN
    --if we are directly on the database log with oracle user
    l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), USER);
    l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'),
                        '999999999999999999999999D999',
                        'NLS_NUMERIC_CHARACTERS = ''. ''');

    IF inserting
    THEN
        :NEW.create_user        := l_str1;
        :NEW.create_time        := current_timestamp;
        :NEW.create_institution := l_str2;
        --
        :NEW.update_user        := NULL;
        :NEW.update_time        := CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE);
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
        pk_alertlog.log_error('B_IU_APRT_AUDIT-' || SQLERRM);
END b_iu_aprt_audit;
/
