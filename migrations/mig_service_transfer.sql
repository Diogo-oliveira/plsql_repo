DECLARE

    l_limit  PLS_INTEGER := 1000;
    l_string VARCHAR2(1000 CHAR);

    CURSOR c_get_recs IS
        SELECT *
          FROM epis_prof_resp epr
         WHERE epr.flg_transf_type = 'S'
           AND ((epr.flg_status = 'X' AND epr.dt_end_transfer_tstz IS NULL)
            OR epr.flg_status = 'T')
           AND epr.id_movement IS NOT NULL;

    TYPE cursor1_type IS TABLE OF c_get_recs%ROWTYPE;
    l_get_recs cursor1_type;

BEGIN

    OPEN c_get_recs;
    LOOP
        FETCH c_get_recs BULK COLLECT
            INTO l_get_recs LIMIT l_limit;
    
        FOR i IN 1 .. l_get_recs.count
        LOOP
        
            UPDATE epis_prof_resp epr
               SET epr.flg_status = 'I'
             WHERE epr.id_epis_prof_resp = l_get_recs(i).id_epis_prof_resp
               AND epr.id_episode = l_get_recs(i).id_episode
               AND epr.flg_transf_type = l_get_recs(i).flg_transf_type;
        
        END LOOP;
        EXIT WHEN c_get_recs%NOTFOUND;
    END LOOP;

END;
/


-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 08/06/2011 14:40
-- CHANGE REASON: [ALERT-182943] 
DECLARE

    l_limit  PLS_INTEGER := 1000;
    l_string VARCHAR2(1000 CHAR);

    CURSOR c_get_recs IS
        SELECT *
          FROM epis_prof_resp epr
         WHERE epr.flg_transf_type = 'S'
           AND ((epr.flg_status = 'X' AND epr.dt_end_transfer_tstz IS NULL)
            OR epr.flg_status = 'T')
           AND epr.id_movement IS NOT NULL;

    TYPE cursor1_type IS TABLE OF c_get_recs%ROWTYPE;
    l_get_recs cursor1_type;

BEGIN

    OPEN c_get_recs;
    LOOP
        FETCH c_get_recs BULK COLLECT
            INTO l_get_recs LIMIT l_limit;
    
        FOR i IN 1 .. l_get_recs.count
        LOOP
        
            UPDATE epis_prof_resp epr
               SET epr.flg_status = 'I'
             WHERE epr.id_epis_prof_resp = l_get_recs(i).id_epis_prof_resp
               AND epr.id_episode = l_get_recs(i).id_episode
               AND epr.flg_transf_type = l_get_recs(i).flg_transf_type;
        
        END LOOP;
        EXIT WHEN c_get_recs%NOTFOUND;
    END LOOP;

END;
/


-- CHANGE END: Filipe Silva