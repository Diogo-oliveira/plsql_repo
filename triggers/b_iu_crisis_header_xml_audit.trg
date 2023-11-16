-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 26-03-2012
-- CHANGE REASON: ALERT-224860
DECLARE
    l_trigger_name table_varchar := table_varchar();
    l_rowcount     NUMBER := 0;
BEGIN
    BEGIN
        SELECT ut.trigger_name BULK COLLECT
          INTO l_trigger_name
          FROM user_triggers ut
         WHERE ut.table_name = 'CRISIS_HEADER_XML'
           AND ut.trigger_name LIKE 'B_IU%AUDIT';
    EXCEPTION
        WHEN OTHERS THEN
            l_trigger_name := table_varchar();
    END;

    FOR i IN 1 .. l_trigger_name.count
    LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || l_trigger_name(i);
        l_rowcount := l_rowcount + 1;
    END LOOP;

    dbms_output.put_line('Audit triggers for CRISIS_HEADER_XML dropped');
END;
/
-- CHANGE END: Gustavo Serrano