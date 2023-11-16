-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:32
-- CHANGE REASON: [ALERT-206286] 02_ALERT_DDLS
grant select on sys_domain to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant select on sys_domain to alert_inter;
-- CHANGE END: Pedro Quinteiro

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
    run_ddl(i_sql => 'REVOKE SELECT on sys_domain from alert_core_func');

    run_ddl(i_sql => 'GRANT SELECT on sys_domain to alert_core_func');

END;
/
-- CHANGE END:  Gisela Couto


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SYS_DOMAIN to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.sys_domain to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes

-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 19/01/2018 16:02
-- CHANGE REASON: [ALERT-335179 ] 
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON sys_domain TO alert_pharmacy_func WITH GRANT OPTION');
END;
/
-- CHANGE END: cristina.oliveira