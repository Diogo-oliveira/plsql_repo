CREATE OR REPLACE TRIGGER b_u_protocol_process_element
    BEFORE UPDATE ON protocol_process_element
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
DECLARE
BEGIN
    IF updating
    THEN
        INSERT INTO protocol_process_element_hist
            (id_protocol_process_elem_hist,
             id_protocol_process_elem,
             flg_status_old,
             flg_status_new,
             id_request_old,
             id_request_new,
             dt_request_old,
             dt_request_new,
             flg_active_old,
             flg_active_new,
             dt_status_change,
             id_professional,
             id_cancel_reason,
             cancel_notes)
            (SELECT seq_protocol_process_elem_hist.nextval,
                    :old.id_protocol_process_elem,
                    :old.flg_status,
                    :new.flg_status,
                    :old.id_request,
                    :new.id_request,
                    :old.dt_request,
                    :new.dt_request,
                    :old.flg_active,
                    :new.flg_active,
                    current_timestamp,
                    :new.id_professional,
                    :new.id_cancel_reason,
                    :new.cancel_notes                    
               FROM dual);
    END IF;
END;
/
