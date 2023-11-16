CREATE OR REPLACE TRIGGER b_ui_audit_quest_answer
    BEFORE INSERT OR UPDATE ON audit_quest_answer
    FOR EACH ROW
-- PL/SQL Block
BEGIN
    :NEW.adw_last_update := SYSDATE;
END b_ui_audit_quest_answer;
/
