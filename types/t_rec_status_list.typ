-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 05/09/2012 14:24
-- CHANGE REASON: [ALERT-239422] 
declare
e_object_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_object_exists, -02303);
begin
  EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_status_list AS object
(
    label      VARCHAR2(1000 CHAR),
    data       VARCHAR2(1000 CHAR),
    icon       VARCHAR2(1000 CHAR),
    flg_action VARCHAR2(1000 CHAR)
)';
EXCEPTION
        WHEN e_object_exists THEN
            dbms_output.put_line('AVISO: Operação já executada anteriormente.');
end;
/
-- CHANGE END: Paulo Teixeira