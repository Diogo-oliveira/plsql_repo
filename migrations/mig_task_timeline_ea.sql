-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 01/04/2011 
-- CHANGE REASON: [ALERT-166051] 
DECLARE

    CURSOR c_get_records IS
        SELECT tte.id_task_refid, tte.id_tl_task, tte.id_patient, tte.id_episode, tte.id_visit, tte.status_str
          FROM task_timeline_ea tte
         WHERE tte.id_tl_task IN (10, 11);

    TYPE t_get_records IS TABLE OF c_get_records%ROWTYPE;
    l_get_records t_get_records;

    l_inp_icon  VARCHAR2(30 CHAR) := 'DetailInternmentIcon';
    l_oris_icon VARCHAR2(30 CHAR) := 'SurgeryIcon';
    l_limit     PLS_INTEGER := 1000;
    l_exception EXCEPTION;

BEGIN

    OPEN c_get_records;
    LOOP
        FETCH c_get_records BULK COLLECT
            INTO l_get_records LIMIT l_limit;
    
        FOR i IN 1 .. l_get_records.count
        LOOP
        
            IF l_get_records(i).id_tl_task = 10
            THEN
            
                UPDATE task_timeline_ea tte
                   SET tte.status_str = regexp_replace(l_get_records(i).status_str, '#', l_oris_icon)
                 WHERE tte.id_task_refid = l_get_records(i).id_task_refid
                   AND tte.id_tl_task = l_get_records(i).id_tl_task
                   AND tte.id_patient = l_get_records(i).id_patient
                   AND tte.id_episode = l_get_records(i).id_episode
                   AND tte.id_visit = l_get_records(i).id_visit;
            
            END IF;
        
            IF l_get_records(i).id_tl_task = 11
            THEN
            
                UPDATE task_timeline_ea tte
                   SET tte.status_str = regexp_replace(l_get_records(i).status_str, '#', l_inp_icon)
                 WHERE tte.id_task_refid = l_get_records(i).id_task_refid
                   AND tte.id_tl_task = l_get_records(i).id_tl_task
                   AND tte.id_patient = l_get_records(i).id_patient
                   AND tte.id_episode = l_get_records(i).id_episode
                   AND tte.id_visit = l_get_records(i).id_visit;
            
            END IF;
        
        END LOOP;
    
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;
/
-- CHANGE END: Filipe Silva
