DECLARE
    l_idx  PLS_INTEGER;
    l_aux  VARCHAR2(4000);
    l_aux2 VARCHAR2(4000);
BEGIN

    FOR rec IN (SELECT *
                  FROM grid_task gt
                 WHERE gt.monitorization IS NOT NULL)
    LOOP
        l_idx := instr(rec.monitorization, '|');
        IF l_idx > 0
        THEN
            l_aux := substr(rec.monitorization, 1, l_idx - 1);
            IF (l_aux <> '14')
            THEN
                l_aux2 := '14' || substr(rec.monitorization, l_idx + length('|') - 1);
                
                UPDATE grid_task g
                   SET g.monitorization = l_aux2
                 WHERE g.id_grid_task = rec.id_grid_task;
                
            END IF;
        
        END IF;
    END LOOP;
END;
/
