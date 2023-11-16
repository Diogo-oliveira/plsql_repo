-- CHANGED BY: Sofia Mendes
-- CHANGED DATE: 2010-JAN-14
-- CHANGED REASON: ALERT-67079 
   BEGIN
        EXECUTE IMMEDIATE 'drop trigger B_IU_148596_AUDIT';
    EXCEPTION
        WHEN others THEN
            dbms_output.put_line('AVISO: Operação já executada anteriormente.');
    END;
-- CHANGE END: Sofia Mendes
