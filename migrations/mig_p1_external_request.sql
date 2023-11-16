-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2013-JAN-04
-- CHANGED REASON: ALERT-194568
DECLARE
    l_count PLS_INTEGER;
    l_aux   PLS_INTEGER;
BEGIN
    -- obter valor original
    BEGIN
        SELECT degree
          INTO l_aux
          FROM user_tables
         WHERE table_name = 'P1_EXTERNAL_REQUEST';
    EXCEPTION
        WHEN no_data_found THEN
            l_aux := 1;
    END;

    -- obter o n de cpus para paralelizar
    SELECT VALUE
      INTO l_count
      FROM v$parameter
     WHERE name = 'cpu_count';

    -- alterar a tabela
    EXECUTE IMMEDIATE 'ALTER TABLE P1_EXTERNAL_REQUEST PARALLEL (DEGREE ' || l_count || ')';

    -- fazer script de migracao de uma so vez
    UPDATE p1_external_request
       SET year_begin  = extract(YEAR FROM dt_probl_begin_tstz),
           month_begin = extract(MONTH FROM dt_probl_begin_tstz),
           day_begin   = extract(DAY FROM dt_probl_begin_tstz)
     WHERE dt_probl_begin_tstz IS NOT NULL;

    -- repor valor original
    EXECUTE IMMEDIATE 'ALTER TABLE P1_TRACKING PARALLEL (DEGREE ' || l_aux || ')';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(SQLCODE || ' / ' || SQLERRM);
END;
/
-- CHANGE END: Ana Monteiro
