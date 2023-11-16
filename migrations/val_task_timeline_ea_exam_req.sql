-- CHANGED BY: Sofia Mendes
-- CHANGE REASON: ALERT-69406 Single page note for Discharge Summary
DECLARE
    /* Leave as is */
    PROCEDURE log_error(i_text IN VARCHAR2) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => 'MIGRATION');
    END log_error;

    /* Leave as is */
    PROCEDURE announce_error IS
    BEGIN
        dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION'' section. Example:
select *
  from alertlog.tlog
 where lsection = ''MIGRATION''
 order by 2 desc, 3 desc, 1 desc;');
    END announce_error;

    /* Leave as is */
    FUNCTION should_execute RETURN BOOLEAN IS
    BEGIN
        RETURN &exec_val = 1;
    END should_execute;

    /* Edit this function */
    PROCEDURE do_my_validation IS
        /* Declarations */
        /* example: */
        e_has_findings EXCEPTION;
        l_count_det_task      PLS_INTEGER := 0;
        l_count_det_task_hist PLS_INTEGER := 0;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT COUNT(1)
          INTO l_count_det_task
          FROM (SELECT CASE
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
                 WHERE e.id_task_type = 4) t
         WHERE t.id_tl_task <> t.id_task_type;
    
        SELECT COUNT(1)
          INTO l_count_det_task_hist
          FROM (SELECT CASE
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
                 WHERE e.id_task_type = 4) t
         WHERE t.id_tl_task <> t.id_task_type;
    
        IF l_count_det_task > 0
           OR l_count_det_task_hist > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of records with id_tl_task different from id_task_type in epis_pn_det_task: ' ||
                      l_count_det_task ||
                      '. Nr of records with id_tl_task different from id_task_type in epis_pn_det_task_hist: ' ||
                      l_count_det_task_hist);
            /* in the end call announce_error to warn the installation script */
            announce_error;
    END do_my_validation;

BEGIN
    /* Leave as is */
    IF should_execute
    THEN
        do_my_validation;
    END IF;

EXCEPTION
    /* Leave as is */
    WHEN OTHERS THEN
        log_error('UNEXPECTED ERROR: ' || SQLERRM);
        announce_error;
END;
/
