-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 18/Ago/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
DECLARE
    l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
    l_ids_templ           table_number := table_number();
    l_ids_task            table_number := table_number();
    l_index               PLS_INTEGER;
BEGIN
    FOR rec IN (SELECT p.id_epis_pn_det_templ,
                       p.id_epis_pn_det,
                       p.id_epis_documentation id_task,
                       1 id_pn_task_type,
                       p.flg_status,
                       p.pn_note,
                       p.dt_last_update,
                       (SELECT epd.id_professional
                          FROM epis_pn_det epd
                         WHERE epd.id_epis_pn_det = p.id_epis_pn_det
                           AND rownum = 1) id_prof_last_update,
                       p.flg_table_origin
                  FROM epis_pn_det_templ p
                 WHERE (p.id_epis_pn_det, p.id_epis_documentation) NOT IN
                       (SELECT epdt.id_epis_pn_det, epdt.id_task
                          FROM epis_pn_det_task epdt))
    LOOP
    
        l_id_epis_pn_det_task := seq_epis_pn_det_task_work.nextval;
    
        INSERT INTO epis_pn_det_task
            (id_epis_pn_det_task,
             id_epis_pn_det,
             id_task,
             id_task_type,
             flg_status,
             pn_note,
             dt_last_update,
             id_prof_last_update,
             flg_table_origin)
        VALUES
            (l_id_epis_pn_det_task,
             rec.id_epis_pn_det,
             rec.id_task,
             rec.id_pn_task_type,
             rec.flg_status,
             rec.pn_note,
             rec.dt_last_update,
             rec.id_prof_last_update,
             rec.flg_table_origin);
    
        l_ids_templ.extend(1);
        l_ids_templ(l_ids_templ.last) := rec.id_epis_pn_det_templ;
        l_ids_task.extend(1);
        l_ids_task(l_ids_task.last) := l_id_epis_pn_det_task;
    
    END LOOP;

    FOR rec IN (SELECT p.id_epis_pn_det_templ,
                       p.dt_epis_pn_det_templ_hist dt_epis_pn_det_task_hist,
                       p.id_epis_pn_det,
                       p.id_epis_documentation id_task,
                       1 id_pn_task_type,
                       p.flg_status,
                       p.pn_note,
                       p.dt_last_update,
                       (SELECT epd.id_professional
                          FROM epis_pn_det epd
                         WHERE epd.id_epis_pn_det = p.id_epis_pn_det
                           AND rownum = 1) id_prof_last_update,
                       p.flg_table_origin
                  FROM epis_pn_det_templ_hist p)
    LOOP
        l_index               := NULL;
        l_id_epis_pn_det_task := NULL;
    
        FOR i IN 1 .. l_ids_templ.count
        LOOP
            IF (l_ids_templ(i) = rec.id_epis_pn_det_templ)
            THEN
                l_index := i;
                EXIT;
            END IF;
        END LOOP;
    
        IF (l_index IS NOT NULL)
        THEN
            l_id_epis_pn_det_task := l_ids_task(l_index);
        END IF;
    
        BEGIN
            INSERT INTO epis_pn_det_task_hist
                (id_epis_pn_det_task,
                 dt_epis_pn_det_task_hist,
                 id_epis_pn_det,
                 id_task,
                 id_task_type,
                 flg_status,
                 pn_note,
                 dt_last_update,
                 id_prof_last_update,
                 flg_table_origin)
            VALUES
                (l_id_epis_pn_det_task,
                 rec.dt_epis_pn_det_task_hist,
                 rec.id_epis_pn_det,
                 rec.id_task,
                 rec.id_pn_task_type,
                 rec.flg_status,
                 rec.pn_note,
                 rec.dt_last_update,
                 rec.id_prof_last_update,
                 rec.flg_table_origin);
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('l_id_epis_pn_det_task: ' || l_id_epis_pn_det_task ||
                                     ' rec.id_epis_pn_det_templ: ' || rec.id_epis_pn_det_templ || ' l_index: ' ||
                                     l_index);
                RAISE;
        END;
    END LOOP;

END;
/
-- CHANGE END: Sofia Mendes


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 18/Ago/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
DECLARE
    l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
    l_ids_templ           table_number := table_number();
    l_ids_task            table_number := table_number();
    l_index               PLS_INTEGER;
BEGIN
    FOR rec IN (SELECT p.id_epis_pn_det_templ,
                       p.id_epis_pn_det,
                       p.id_epis_documentation id_task,
                       1 id_pn_task_type,
                       p.flg_status,
                       p.pn_note,
                       p.dt_last_update,
                       (SELECT epd.id_professional
                          FROM epis_pn_det epd
                         WHERE epd.id_epis_pn_det = p.id_epis_pn_det
                           AND rownum = 1) id_prof_last_update,
                       p.flg_table_origin
                  FROM epis_pn_det_templ p
                 WHERE (p.id_epis_pn_det, p.id_epis_documentation) NOT IN
                       (SELECT epdt.id_epis_pn_det, epdt.id_task
                          FROM epis_pn_det_task epdt)
                   AND NOT EXISTS (SELECT *
                          FROM epis_pn_det_task ept
                         WHERE ept.id_epis_pn_det = p.id_epis_pn_det
                           AND ept.id_task = p.id_epis_documentation
                           AND ept.id_task_type = 1
                           AND ept.flg_status = p.flg_status))
    LOOP
        SELECT seq_epis_pn_det_task_work.nextval into l_id_epis_pn_det_task FROM dual;
            
        INSERT INTO epis_pn_det_task
            (id_epis_pn_det_task,
             id_epis_pn_det,
             id_task,
             id_task_type,
             flg_status,
             pn_note,
             dt_last_update,
             id_prof_last_update,
             flg_table_origin)
        VALUES
            (l_id_epis_pn_det_task,
             rec.id_epis_pn_det,
             rec.id_task,
             rec.id_pn_task_type,
             rec.flg_status,
             rec.pn_note,
             rec.dt_last_update,
             rec.id_prof_last_update,
             rec.flg_table_origin);
    
        l_ids_templ.extend(1);
        l_ids_templ(l_ids_templ.last) := rec.id_epis_pn_det_templ;
        l_ids_task.extend(1);
        l_ids_task(l_ids_task.last) := l_id_epis_pn_det_task;
    
    END LOOP;

    FOR rec IN (SELECT p.id_epis_pn_det_templ,
                       p.dt_epis_pn_det_templ_hist dt_epis_pn_det_task_hist,
                       p.id_epis_pn_det,
                       p.id_epis_documentation id_task,
                       1 id_pn_task_type,
                       p.flg_status,
                       p.pn_note,
                       p.dt_last_update,
                       (SELECT epd.id_professional
                          FROM epis_pn_det epd
                         WHERE epd.id_epis_pn_det = p.id_epis_pn_det
                           AND rownum = 1) id_prof_last_update,
                       p.flg_table_origin
                  FROM epis_pn_det_templ_hist p
                 WHERE NOT EXISTS (SELECT *
                          FROM epis_pn_det_task_hist eth
                         WHERE eth.id_epis_pn_det = p.id_epis_pn_det
                           AND eth.dt_epis_pn_det_task_hist = p.dt_epis_pn_det_templ_hist
                           AND eth.id_task = p.id_epis_documentation
                           AND eth.id_task_type = 1))
    LOOP
        l_index               := NULL;
        l_id_epis_pn_det_task := NULL;
    
        FOR i IN 1 .. l_ids_templ.count
        LOOP
            IF (l_ids_templ(i) = rec.id_epis_pn_det_templ)
            THEN
                l_index := i;
                EXIT;
            END IF;
        END LOOP;
    
        IF (l_index IS NOT NULL)
        THEN
            l_id_epis_pn_det_task := l_ids_task(l_index);
        END IF;
    
        BEGIN
            INSERT INTO epis_pn_det_task_hist
                (id_epis_pn_det_task,
                 dt_epis_pn_det_task_hist,
                 id_epis_pn_det,
                 id_task,
                 id_task_type,
                 flg_status,
                 pn_note,
                 dt_last_update,
                 id_prof_last_update,
                 flg_table_origin)
            VALUES
                (l_id_epis_pn_det_task,
                 rec.dt_epis_pn_det_task_hist,
                 rec.id_epis_pn_det,
                 rec.id_task,
                 rec.id_pn_task_type,
                 rec.flg_status,
                 rec.pn_note,
                 rec.dt_last_update,
                 rec.id_prof_last_update,
                 rec.flg_table_origin);
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('l_id_epis_pn_det_task: ' || l_id_epis_pn_det_task ||
                                     ' rec.id_epis_pn_det_templ: ' || rec.id_epis_pn_det_templ || ' l_index: ' ||
                                     l_index);
                RAISE;
        END;
    END LOOP;

END;
/
-- CHANGE END: Sofia Mendes
