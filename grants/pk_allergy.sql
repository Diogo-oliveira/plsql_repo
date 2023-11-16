-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 29-APR-2011
-- CHANGE REASON: [ALERT-175361] 
grant execute on pk_allergy to alert_reset;
-- CHANGE END

GRANT EXECUTE ON ALERT.pk_allergy TO ALERT_INTER;

-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 21/08/2014 10:25
-- CHANGE REASON: [ALERT-291116] Document archive> Drug allergies >> reconciliation functional area >> drug allergies record in previous episodes doesn't appears in EHR
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || replace(SRCSTR => SQLERRM, OLDSUB => 'ORA-', NEWSUB => '') || '; ' || i_sql || ';');
    END run_ddl;

BEGIN

    run_ddl(i_sql => 'GRANT EXECUTE,DEBUG on pk_allergy TO alert_inter');
END;
/
-- CHANGE END:  Gisela Couto