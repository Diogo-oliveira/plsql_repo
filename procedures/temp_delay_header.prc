CREATE OR REPLACE PROCEDURE temp_delay_header
(
    i_id_episode NUMBER,
    i_id_patient NUMBER
    
) AS

    CURSOR get_delay IS
        SELECT delay
          FROM temp_episode_delay
         WHERE patient = nvl(i_id_patient,
                             patient)
           AND episode = nvl(i_id_episode,
                             episode)
           AND rownum = 1;

    l_delay NUMBER;

BEGIN
    l_delay := 0;
    OPEN get_delay;
    FETCH get_delay
        INTO l_delay;
    CLOSE get_delay;

    dbms_lock.sleep(l_delay);

END;
/
DROP PROCEDURE TEMP_DELAY_HEADER;
