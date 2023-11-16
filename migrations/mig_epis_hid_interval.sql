-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 04/04/2011 
-- CHANGE REASON: [ALERT-134135]
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'update epis_hidrics eh
set eh.interval_minutes = (to_date(to_char(SYSDATE, ''dd-mm-yyyy'') || '' '' || eh.interval_value,
                                   ''dd-mm-yyyy HH24:MI'') - trunc(SYSDATE)) * 24 * 60
where eh.interval_value is not null';
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('AVISO: Operação já executada anteriormente.');
    END;
END;
/
