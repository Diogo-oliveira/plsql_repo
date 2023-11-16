-->ast_mkt_vrs|trg
CREATE OR REPLACE TRIGGER alert_default.b_iu_ASTMV
    BEFORE INSERT OR UPDATE ON alert_default.ast_mkt_vrs
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
        alertlog.pk_alertlog.log_error('B_IU_ASTMV_DT_CNT- ' || SQLERRM);
END b_iu_ASTMV;
/
