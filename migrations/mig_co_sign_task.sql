-- CHANGED BY: Joana Madureira Barroso
-- CHANGE DATE: 05/03/2014 
-- CHANGE REASON: [ALERT-277666]

-- order 
DECLARE
    CURSOR c_cur IS(
        SELECT p.id_presc, p.id_co_sign
          FROM v_presc_plan_task p
         WHERE p.id_presc IN (SELECT c.id_task
                                FROM co_sign_task c
                               WHERE c.flg_type = 'P')
           AND p.id_co_sign IS NOT NULL);
    l_cur_row c_cur%ROWTYPE;
BEGIN

    OPEN c_cur;
    FETCH c_cur
        INTO l_cur_row;

    WHILE (c_cur%FOUND)
    LOOP
        UPDATE co_sign_task
           SET id_task = l_cur_row.id_co_sign
         WHERE id_task = l_cur_row.id_presc
           AND flg_type = 'P';
    
        FETCH c_cur
            INTO l_cur_row;    
    END LOOP;

    CLOSE c_cur;

END;
/

--administração
DECLARE
    CURSOR c_cur IS(
        SELECT p.id_presc, p.id_co_sign
          FROM v_presc_tab p
         WHERE p.id_presc IN (SELECT c.id_task
                                FROM co_sign_task c
                               WHERE c.flg_type = 'P')
           AND p.id_co_sign IS NOT NULL);
    l_cur_row c_cur%ROWTYPE;
    l_exception EXCEPTION;

    PRAGMA EXCEPTION_INIT(l_exception, -00001); -- UTK_UK

BEGIN

    OPEN c_cur;
    FETCH c_cur
        INTO l_cur_row;

    WHILE (c_cur%FOUND)
    LOOP
        BEGIN
            UPDATE co_sign_task
               SET id_task = l_cur_row.id_co_sign
             WHERE id_task = l_cur_row.id_presc
               AND flg_type = 'P';
        EXCEPTION
            WHEN l_exception THEN
                dbms_output.put_line('Id já migrado / ID_CO_SIGN=' || l_cur_row.id_co_sign || ', ID_PRESC=' ||
                                     l_cur_row.id_presc);
                                     
        END;
    
        FETCH c_cur
            INTO l_cur_row;
    END LOOP;

    CLOSE c_cur;

END;
/

-- CHANGE END: Joana Madureira Barroso