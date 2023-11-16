-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 14/12/2010 15:20
-- CHANGE REASON: [ALERT-138297] 
DECLARE
    l_parent             NUMBER(24);
    l_id_epis_mtos_score NUMBER(24);

    CURSOR c_ems IS
        SELECT id_parent, id_epis_mtos_score
          FROM (SELECT row_number() over(ORDER BY t.dt_create DESC) r, t.*
                  FROM (SELECT (SELECT MAX(ems2.id_epis_mtos_score) id_parent
                                  FROM epis_mtos_score ems2
                                 WHERE ems2.id_episode = ems.id_episode
                                   AND ems2.dt_create < ems.dt_create) id_parent,
                               ems.*
                          FROM epis_mtos_score ems
                         ORDER BY ems.id_episode, ems.dt_create DESC) t
                 ORDER BY id_episode, dt_create, r);

BEGIN

    OPEN c_ems;
    LOOP
    
        FETCH c_ems
            INTO l_parent, l_id_epis_mtos_score;
        EXIT WHEN c_ems%NOTFOUND;
    
        IF l_parent IS NOT NULL
        THEN
            
            UPDATE epis_mtos_score ems SET ems.id_epis_mtos_score_parent = l_parent WHERE ems.id_epis_mtos_score = l_id_epis_mtos_score;

        END IF;
    END LOOP;

END;
/
-- CHANGE END: Tércio Soares