-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 18/06/2014 15:00
-- CHANGE REASON: [ALERT-288031] 
DECLARE e_expt EXCEPTION;
PRAGMA EXCEPTION_INIT(e_expt, -00904);
BEGIN
    UPDATE cdr_event cde
       SET cde.id_cdr_event = seq_cdr_event.nextval
     WHERE cde.id_cdr_event is NULL;
EXCEPTION
    WHEN e_expt THEN
        dbms_output.put_line('already executed');
END;
/
-- CHANGE END: mario.mineiro