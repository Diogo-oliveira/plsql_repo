BEGIN
    <<track_update>>
    FOR i IN 1 .. 10000
    LOOP
        UPDATE p1_tracking
           SET flg_subtype = 'C'
         WHERE id_tracking IN
               (SELECT tab1.id_tracking
                  FROM (SELECT t.id_external_request,
                               lag(t.id_external_request, 1) over(ORDER BY t.id_external_request, t.dt_tracking_tstz) prev_id_ext_req,
                               t.id_tracking,
                               t.ext_req_status,
                               lag(t.ext_req_status, 1) over(ORDER BY t.id_external_request, t.dt_tracking_tstz) prev_flg_status,
                               flg_subtype,
                               id_workflow_action
                          FROM p1_tracking t
                         WHERE t.flg_type NOT IN ('R', 'U', 'T')
                         ORDER BY t.id_external_request, t.dt_tracking_tstz) tab1
                 WHERE ext_req_status = 'A'
                   AND decode(tab1.prev_id_ext_req, tab1.id_external_request, tab1.prev_flg_status, NULL) IN ('S', 'M')
                   AND (flg_subtype IS NULL OR flg_subtype != 'C') -- nao retorna os que ja foram actualizados
                   AND rownum < 4000);
    
        IF SQL%ROWCOUNT = 0
        THEN
            EXIT track_update;
        END IF;
    
        COMMIT;
    
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN        
		ROLLBACK;
		dbms_output.put_line(SQLCODE||' / '||SQLERRM);
END;
/

-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2012-JUN-01
-- CHANGED REASON: ALERT-230846
DECLARE
    l_lang  language.id_language%TYPE;
    l_prof  profissional;
    l_limit PLS_INTEGER := 2000;

    CURSOR c_track IS
        SELECT t.id_tracking, p.id_speciality
          FROM p1_tracking t
          JOIN p1_external_request p
            ON p.id_external_request = t.id_external_request
         WHERE (p.id_workflow IN (1, 2, 3, 4, 8) OR p.id_workflow IS NULL)
           AND t.id_dep_clin_serv IS NOT NULL
           AND t.id_speciality IS NULL
           AND p.id_speciality IS NOT NULL
           AND p.flg_type = 'C';

    CURSOR c_track_sts(x_flg_status IN p1_tracking.ext_req_status%TYPE) IS
        SELECT t.id_tracking, p.id_speciality
          FROM (SELECT t1.id_tracking,
                       t1.id_speciality,
                       t1.id_external_request,
                       t1.ext_req_status,
                       row_number() over(PARTITION BY t1.id_external_request ORDER BY t1.dt_tracking_tstz ASC) my_row
                  FROM p1_tracking t1
                 WHERE t1.flg_type = 'S'
                   AND t1.ext_req_status = x_flg_status) t
          JOIN p1_external_request p
            ON p.id_external_request = t.id_external_request
         WHERE t.my_row = 1
           AND (p.id_workflow IN (1, 2, 3, 4, 8) OR p.id_workflow IS NULL)
           AND t.id_speciality IS NULL
           AND p.id_speciality IS NOT NULL
           AND p.flg_type = 'C';

    l_tab_id_track  table_number;
    l_tab_id_spec   table_number;
    l_id_speciality p1_speciality.id_speciality%TYPE;
    l_error         VARCHAR2(1000 CHAR);
BEGIN
    -- Migration of other status
    l_error        := 'Migration of other status';
    l_tab_id_track := table_number();
    l_tab_id_spec  := table_number();

    OPEN c_track;
    LOOP
        FETCH c_track BULK COLLECT
            INTO l_tab_id_track, l_tab_id_spec LIMIT l_limit;
    
        l_error := '(1) FORALL i IN 1 .. ' || l_tab_id_track.count;
        FORALL i IN 1 .. l_tab_id_track.count SAVE EXCEPTIONS
            UPDATE p1_tracking
               SET id_speciality = l_tab_id_spec(i)
             WHERE id_tracking = l_tab_id_track(i);
    
        COMMIT;
        EXIT WHEN l_tab_id_track.count < l_limit;
    
    END LOOP;

    CLOSE c_track;

    -- Migration of status N
    l_error        := 'Migration of status N';
    l_tab_id_track := table_number();
    l_tab_id_spec  := table_number();

    OPEN c_track_sts('N');
    LOOP
        FETCH c_track_sts BULK COLLECT
            INTO l_tab_id_track, l_tab_id_spec LIMIT l_limit;
    
        l_error := '(2) FORALL i IN 1 .. ' || l_tab_id_track.count;
        FORALL i IN 1 .. l_tab_id_track.count SAVE EXCEPTIONS
            UPDATE p1_tracking
               SET id_speciality = l_tab_id_spec(i)
             WHERE id_tracking = l_tab_id_track(i);
    
        COMMIT;
        EXIT WHEN l_tab_id_track.count < l_limit;
    
    END LOOP;

    CLOSE c_track_sts;

    -- Migration of status O
    l_error        := 'Migration of status O';
    l_tab_id_track := table_number();
    l_tab_id_spec  := table_number();

    OPEN c_track_sts('O');
    LOOP
        FETCH c_track_sts BULK COLLECT
            INTO l_tab_id_track, l_tab_id_spec LIMIT l_limit;
    
        l_error := '(3) FORALL i IN 1 .. ' || l_tab_id_track.count;
        FORALL i IN 1 .. l_tab_id_track.count SAVE EXCEPTIONS
            UPDATE p1_tracking
               SET id_speciality = l_tab_id_spec(i)
             WHERE id_tracking = l_tab_id_track(i);
    
        COMMIT;
        EXIT WHEN l_tab_id_track.count < l_limit;
    
    END LOOP;

    CLOSE c_track_sts;
END;
/
-- CHANGE END: Ana Monteiro