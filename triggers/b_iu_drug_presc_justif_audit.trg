
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRUG_PRESC_JUSTIF_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_PRESC_JUSTIFICATION
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
	l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
	l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

	IF inserting
	THEN
	  :NEW.create_user        := l_str1;
	  :NEW.create_time        := current_timestamp;
	  :NEW.create_institution := l_str2;
	ELSIF updating
	THEN
	  :NEW.update_user        := l_str1;
	  :NEW.update_time        := current_timestamp;
	  :NEW.update_institution := l_str2;
	END IF;
EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_PRESC_JUSTIF_AUDIT-' || sqlerrm);
END B_IU_DRUG_PRESC_JUSTIF_AUDIT;
/
