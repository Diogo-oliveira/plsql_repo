-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 16:39
-- CHANGE REASON: [ALERT-174012] Creation of Columns and Types - Update functionality positionings to function with detail and history

begin
EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_table_history_data IS TABLE OF t_rec_history_data';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
end;
/

-- CHANGE END: António Neto