CREATE OR REPLACE TRIGGER b_ui_audit_req_prof
    BEFORE INSERT OR UPDATE ON audit_req_prof
 FOR EACH ROW
-- PL/SQL Block
BEGIN
    :NEW.adw_last_update := SYSDATE;
END b_ui_audit_req_prof;
/
