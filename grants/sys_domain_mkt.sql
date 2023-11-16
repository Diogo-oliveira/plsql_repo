-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 31/07/2014 09:52
-- CHANGE REASON: [ALERT-291995] Dev DB - Multichoice domain tables implementation - Grants/Synonyms - schema alert
DECLARE
    l_seq_code    VARCHAR2(4000 CHAR);
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ' ||
                                 i_sql || ';');
    END run_ddl;

    
BEGIN

    run_ddl(i_sql => 'REVOKE SELECT on sys_domain_mkt from alert_core_func');

    run_ddl(i_sql => 'GRANT SELECT on sys_domain_mkt to alert_core_func');
END;
/
-- CHANGE END:  Gisela Couto