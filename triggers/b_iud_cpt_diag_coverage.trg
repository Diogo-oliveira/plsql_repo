CREATE OR REPLACE
TRIGGER b_iud_cpt_diag_coverage
    BEFORE INSERT OR UPDATE OR DELETE ON cpt_diag_coverage
    FOR EACH ROW
DECLARE
    -- local variables here
    l_oper VARCHAR2(3);
BEGIN
    IF deleting
    THEN
        l_oper := 'DEL';
    ELSIF updating
    THEN
        l_oper := 'UPD';
    END IF;

    IF deleting
       OR updating
    THEN
        INSERT INTO cpt_diag_coverage_hist
            (cpt_code, code_icd, id_room, id_health_plan, operation, dt_operation)
        VALUES
            (:OLD.cpt_code, :OLD.code_icd, :OLD.id_room, :OLD.id_health_plan, l_oper, SYSDATE);
    ELSE
        INSERT INTO cpt_diag_coverage_hist
            (cpt_code, code_icd, id_room, id_health_plan, operation, dt_operation)
        VALUES
            (:NEW.cpt_code, :NEW.code_icd, :NEW.id_room, :NEW.id_health_plan, 'INS', SYSDATE);
    END IF;
END b_iud_cpt_diag_coverage;
/
