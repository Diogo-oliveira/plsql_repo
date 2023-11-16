-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 04/04/2011 
-- CHANGE REASON: [ALERT-134135]
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'update hidrics_interval hi
set hi.interval_minutes = (to_date(to_char(SYSDATE, ''dd-mm-yyyy'') || '' '' || hi.interval_value,
                                   ''dd-mm-yyyy HH24:MI'') - trunc(SYSDATE)) * 24 * 60
where hi.interval_value is not null';
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('AVISO: Operação já executada anteriormente.');
    END;

    UPDATE hidrics_interval h
       SET h.interval_minutes = 1440
     WHERE h.id_hidrics_interval = 12;
END;
/
