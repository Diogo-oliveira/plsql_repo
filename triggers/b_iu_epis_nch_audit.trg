CREATE OR REPLACE TRIGGER b_iu_epis_nch_audit
    BEFORE INSERT OR UPDATE ON epis_nch
    FOR EACH ROW
DECLARE
BEGIN
    IF pk_utils.str_token(pk_utils.get_client_id, 1, ';') IS NULL
    THEN
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
END b_iu_epis_nch_audit;
/
