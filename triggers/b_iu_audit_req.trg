CREATE OR REPLACE TRIGGER b_ui_audit_req
    BEFORE INSERT OR UPDATE ON audit_req
    FOR EACH ROW
-- PL/SQL Block
BEGIN
    :NEW.adw_last_update := SYSDATE;
END b_ui_audit_req;
/
