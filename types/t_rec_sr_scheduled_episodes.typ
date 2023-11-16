-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 02/06/2010 18:02
-- CHANGE REASON: [ALERT-102331] Added API for Crisis Machine
DECLARE
    e_object_exists EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_object_exists, -02303);

BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_sr_scheduled_episodes IS OBJECT(id_episode NUMBER(24), id_patient NUMBER(24))';
EXCEPTION
    WHEN e_object_exists THEN
        dbms_output.put_line('AVISO: Operação já executada anteriormente.');
END;
/
-- CHANGE END: Gustavo Serrano