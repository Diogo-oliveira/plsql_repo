-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 16:31
-- CHANGE REASON: [ALERT-174012] Creation of Columns and Types - Update functionality positionings to function with detail and history
begin
EXECUTE IMMEDIATE 'GRANT SELECT ON EPIS_POSIT_PLAN_HIST TO ALERT_VIEWER';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
end;
/
-- CHANGE END: António Neto