-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 12/03/2010 17:05
-- CHANGE REASON: [ALERT-81062] ALERT_679 Development
CREATE OR REPLACE TRIGGER B_IU_WTL_DOCUMENTATION_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WTL_DOCUMENTATION
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
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WTL_DOCUMENTATION_AUDIT-'||sqlerrm);
END B_IU_WTL_DOCUMENTATION_AUDIT;
/
-- CHANGE END: Gustavo Serrano