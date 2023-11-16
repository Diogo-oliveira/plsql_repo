CREATE OR REPLACE FUNCTION convert_grid_task
(
    i_institution IN NUMBER,
    i_str         IN VARCHAR2
) RETURN VARCHAR2 IS
    l_aux1 VARCHAR2(200);
    l_aux2 VARCHAR2(200);

    l_tz VARCHAR2(200);

    CURSOR c_tz IS
        SELECT b.timezone_region
          FROM institution a, timezone_region b
         WHERE a.id_timezone_region = b.id_timezone_region(+)
           AND a.id_institution = i_institution;

BEGIN

    OPEN c_tz;
    FETCH c_tz
        INTO l_tz;
    CLOSE c_tz;

    SELECT pk_utils.str_token(i_str, 2, '|')
      INTO l_aux1
      FROM dual;

    IF length(l_aux1) > 14 or l_tz is null
    THEN
        RETURN i_str;
    END IF;

    IF l_aux1 != 'xxxxxxxxxxxxxx'
    THEN
        l_aux2 := l_aux1 || ' ' || l_tz;
    ELSE
        RETURN i_str;
    END IF;

    RETURN REPLACE(i_str, l_aux1, l_aux2);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Err:' || SQLERRM);
        RETURN NULL;
END convert_grid_task;
/
