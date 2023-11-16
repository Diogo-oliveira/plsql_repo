-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 21/04/2010 11:26
-- CHANGE REASON: [ALERT-91154] Registration POS
CREATE OR REPLACE TRIGGER B_IU_SR_POS_PHARM_DET_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.SR_POS_PHARM_DET
FOR EACH ROW
BEGIN
    alert.pk_edit_trail.set_audit_columns(i_is_inserting        => inserting,
                                          i_is_updating         => updating,
                                          io_create_user        => :NEW.create_user,
                                          io_create_time        => :NEW.create_time,
                                          io_create_institution => :NEW.create_institution,
                                          io_update_user        => :NEW.update_user,
                                          io_update_time        => :NEW.update_time,
                                          io_update_institution => :NEW.update_institution);

EXCEPTION
    WHEN OTHERS THEN
        alertlog.pk_alertlog.log_error('B_IU_SR_POS_PHARM_DET_AUDIT-' || SQLERRM);
END b_iu_sr_pos_pharm_det_audit;

drop TRIGGER b_iu_sr_pos_pharm_det_audit;
/
-- CHANGE END: Gustavo Serrano
