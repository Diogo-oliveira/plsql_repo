CREATE OR REPLACE TRIGGER b_u_guideline_process_task
    BEFORE UPDATE ON guideline_process_task
    REFERENCING OLD AS OLD NEW AS NEW
    FOR EACH ROW
DECLARE
BEGIN
    IF updating
    THEN
        INSERT INTO guideline_process_task_hist
            (id_guideline_process_task_hist,
             id_guideline_process_task,
             flg_status_old,
             flg_status_new,
             id_request_old,
             id_request_new,
             dt_request_old,
             dt_request_new,
             dt_status_change,
             id_professional,
             id_cancel_reason,
             cancel_notes)
            (SELECT seq_guideline_process_task_hst.nextval,
                    :old.id_guideline_process_task,
                    :old.flg_status_last,
                    :new.flg_status_last,
                    :old.id_request,
                    :new.id_request,
                    :old.dt_request,
                    :new.dt_request,
                    current_timestamp,
                    :new.id_professional,
                    :new.id_cancel_reason,
                    :new.cancel_notes
               FROM dual);
    
    END IF;
END;
/
