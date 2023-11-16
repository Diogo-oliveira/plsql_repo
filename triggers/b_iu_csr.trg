CREATE OR REPLACE TRIGGER alert_default.b_iu_csr
    BEFORE INSERT OR UPDATE ON alert_default.clinical_serv_rel
    FOR EACH ROW
DECLARE
BEGIN
    IF inserting
    THEN
        :new.dt_content := current_timestamp;
    ELSIF updating
    THEN
        :new.dt_content := current_timestamp;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        alertlog.pk_alertlog.log_error('B_IU_CLINICAL_SERV_REL_DT_CNT-' || SQLERRM);
END b_iu_csr;
/
