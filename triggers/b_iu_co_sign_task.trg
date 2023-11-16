CREATE OR REPLACE TRIGGER b_iu_co_sign_task
    BEFORE INSERT OR UPDATE ON co_sign_task
    FOR EACH ROW
DECLARE
    l_id_task co_sign_task.id_task%TYPE;
BEGIN
    BEGIN
        IF :new.flg_type = 'A'
        THEN
            SELECT ar.id_analysis_req_det
              INTO l_id_task
              FROM analysis_req_det ar
             WHERE ar.id_analysis_req_det = :new.id_task;
        ELSIF :new.flg_type = 'P'
        THEN
            SELECT p.id_presc_validation
              INTO l_id_task
              FROM v_presc_validation p
             WHERE p.id_presc_validation = :new.id_task;
        ELSIF :new.flg_type = 'E'
        THEN
            SELECT er.id_exam_req_det
              INTO l_id_task
              FROM exam_req_det er
             WHERE er.id_exam_req_det = :new.id_task;
        ELSIF :new.flg_type = 'I'
        THEN
            SELECT ip.id_interv_presc_det
              INTO l_id_task
              FROM interv_presc_det ip
             WHERE ip.id_interv_presc_det = :new.id_task;
        ELSIF :new.flg_type = 'M'
        THEN
            SELECT m.id_monitorization_vs
              INTO l_id_task
              FROM monitorization_vs m
             WHERE m.id_monitorization_vs = :new.id_task;
        ELSIF :new.flg_type = 'DD'
        THEN
            SELECT drd.id_drug_req_det
              INTO l_id_task
              FROM drug_req_det drd
             WHERE drd.id_drug_req_det = :new.id_task;
        ELSIF :new.flg_type = 'OP'
        THEN
            SELECT op.id_opinion
              INTO l_id_task
              FROM opinion_prof op
             WHERE op.id_opinion_prof = :new.id_task;
        ELSIF :new.flg_type = 'CO'
        THEN
            SELECT cor.id_comm_order_req
              INTO l_id_task
              FROM comm_order_req cor

             WHERE cor.id_comm_order_req = :new.id_task;
        ELSE
            raise_application_error(-20001, 'Foreign key not available on referred table.');
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            raise_application_error(-20001, 'Foreign key not available on referred table. ID = ' || :new.id_task);
    END;
END;
/