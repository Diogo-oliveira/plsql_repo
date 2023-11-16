CREATE OR REPLACE TRIGGER b_ui_audit_type_triage_type
    BEFORE INSERT OR UPDATE ON audit_type_triage_type
    FOR EACH ROW
-- PL/SQL Block
BEGIN
    :NEW.adw_last_update := SYSDATE;
END b_ui_audit_type_triage_type;
/
