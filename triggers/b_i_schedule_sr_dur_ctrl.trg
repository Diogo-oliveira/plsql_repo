CREATE OR REPLACE TRIGGER b_i_schedule_sr_dur_ctrl
    BEFORE INSERT ON alert.schedule_sr
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.flg_dur_control := nvl(:NEW.flg_dur_control, 'Y');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        alertlog.pk_alertlog.log_error('b_i_schedule_sr_dur_ctrl-' || SQLERRM);
END b_i_schedule_sr_dur_ctrl;
/
