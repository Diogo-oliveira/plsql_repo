-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.ACCIDENT_BR to alert_reset;
-- CHANGE END: Ana Coelho

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 11-APR-2011
-- CHANGE REASON: ALERT-171286 
DECLARE
BEGIN
EXECUTE IMMEDIATE 'grant select, update, delete on ALERT.ACCIDENT_BR to alert_reset';
EXCEPTION
WHEN others THEN
dbms_output.put_line('Nothing done');
END;
/
-- CHANGE END: Ana Coelho