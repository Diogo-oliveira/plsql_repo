-- CHANGED BY: Sofia Mendes
-- CHANGE REASON: ALERT-69406 Single page note for Discharge Summary
DECLARE

    l_id_epis_pn         epis_pn.id_epis_pn%TYPE;
    l_id_epis_pn_det     epis_pn_det.id_epis_pn_det%TYPE;
    l_id_prof_sign_off   epis_pn.id_prof_signoff%TYPE;
    l_dt_sign_off        epis_pn.dt_signoff%TYPE;
    l_id_epis_pn_signoff epis_pn_signoff.id_epis_pn_signoff%TYPE;
    l_date               VARCHAR2(1000 CHAR);

BEGIN

    FOR rec IN (SELECT CASE
                            WHEN ex.flg_type = pk_exam_constant.g_type_img THEN
                             pk_prog_notes_constants.g_task_img_exams_req
                            ELSE
                             pk_prog_notes_constants.g_task_other_exams_req
                        END id_tl_task,
                       ex.flg_type,
                       e.*
                  FROM epis_pn_det_task e
                  JOIN exam_req_det erd
                    ON erd.id_exam_req_det = e.id_task
                  JOIN exam ex
                    ON ex.id_exam = erd.id_exam
                 WHERE e.id_task_type = 4)
    LOOP
        BEGIN
            IF (rec.id_tl_task <> rec.id_task_type)
            THEN
                UPDATE epis_pn_det_task epdt
                   SET epdt.id_task_type = rec.id_tl_task
                 WHERE epdt.id_epis_pn_det_task = rec.id_epis_pn_det_task;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('ERROR: id_epis_pn_det_task: ' || rec.id_epis_pn_det_task || 'id_tl_task: ' ||
                                     rec.id_tl_task || ' id_task_type: ' || rec.id_task_type || ' SQLERR: ' || SQLERRM);
        END;
    
    END LOOP;
    
    
    FOR rec IN (SELECT CASE
                            WHEN ex.flg_type = pk_exam_constant.g_type_img THEN
                             pk_prog_notes_constants.g_task_img_exams_req
                            ELSE
                             pk_prog_notes_constants.g_task_other_exams_req
                        END id_tl_task,
                       ex.flg_type,
                       e.*
                  FROM epis_pn_det_task_hist e
                  JOIN exam_req_det erd
                    ON erd.id_exam_req_det = e.id_task
                  JOIN exam ex
                    ON ex.id_exam = erd.id_exam
                 WHERE e.id_task_type = 4)
    LOOP
        BEGIN
            IF (rec.id_tl_task <> rec.id_task_type)
            THEN
                UPDATE epis_pn_det_task_hist epdt
                   SET epdt.id_task_type = rec.id_tl_task
                 WHERE epdt.id_epis_pn_det_task = rec.id_epis_pn_det_task and epdt.dt_epis_pn_det_task_hist = rec.dt_epis_pn_det_task_hist;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('ERROR hist: id_epis_pn_det_task: ' || rec.id_epis_pn_det_task || ' id_tl_task: ' ||
                                     rec.id_tl_task || ' id_task_type: ' || rec.id_task_type || ' SQLERR: ' || SQLERRM);
        END;
    
    END LOOP;

END;
/
