-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 03/06/2009 08:30
-- CHANGE REASON: [ALERT-30077] 
grant execute on pk_api_patient to alert_adtcod;
-- CHANGE END: Sérgio Santos

-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 22-Feb-2010
-- CHANGE REASON: ALERT-69792 
GRANT EXECUTE ON ALERT.PK_API_PATIENT TO INTER_ALERT_V2;
-- CHANGE END: Paulo Fonseca


-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 17/10/2014 15:49
-- CHANGE REASON: [ALERT-298447] 
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
run_ddl(i_sql => 'GRANT EXECUTE ON ALERT.PK_API_PATIENT to ALERT_INTER');
END;
/
-- CHANGE END: mario.mineiro