-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 02/10/2013
-- CHANGE REASON: [ALERT-266187] Intake and output improvements
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_tbl_hidrics_request AS TABLE OF t_rec_hidrics_request';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('operacao ja executada anteriormente');
END;
/
--CHANGE END: Sofia Mendes