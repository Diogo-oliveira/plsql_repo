-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 31/07/2014 15:54
-- CHANGE REASON: [ALERT-292135] Dev DB - Multichoice domain tables implementation - New packages
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || replace(SRCSTR => SQLERRM, OLDSUB => 'ORA-', NEWSUB => '') || '; ' || i_sql || ';');
    END run_ddl;
BEGIN
    run_ddl(i_sql => 'GRANT EXECUTE ON PK_MULTICHOICE_UX TO alert_viewer');
END;
/
-- CHANGE END:  Gisela Couto