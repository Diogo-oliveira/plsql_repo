
grant execute on pk_diagnosis_core to alert_inter;


-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 30/10/2014 12:34
-- CHANGE REASON: [ALERT-299396] pk_rt_pfh_hie.get_encounter_entries must be able to accept scope parameter so it can retrieve data for episode (scope = E) or last encounter documented for patient (scope = L)
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
    run_ddl(i_sql => 'REVOKE EXECUTE,DEBUG on PK_DIAGNOSIS_CORE from alert_inter');

    run_ddl(i_sql => 'GRANT EXECUTE,DEBUG on PK_DIAGNOSIS_CORE to alert_inter');
END;
/
-- CHANGE END:  Gisela Couto