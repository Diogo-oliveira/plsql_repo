-- CHANGED BY:  sergio.dias
-- CHANGE DATE: 04/10/2013 14:14
-- CHANGE REASON: [ALERT-265915] 
DECLARE
    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ' ||
                                 i_sql || ';');
    END run_ddl;
BEGIN
    run_ddl(i_sql => 'ALTER TRIGGER b_iu_triage_configuration DISABLE');

    UPDATE triage_configuration tc
    set tc.flg_complaint = 'Y'
     WHERE tc.id_triage_type = 6;

    UPDATE triage_configuration tc
    set tc.flg_complaint = 'Y'
     WHERE tc.id_triage_type = 4;

    run_ddl(i_sql => 'ALTER TRIGGER b_iu_triage_configuration ENABLE');
END;
/
-- CHANGE END:  sergio.dias