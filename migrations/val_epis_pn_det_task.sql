-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 18/Ago/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
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
        l_count_templ PLS_INTEGER;
        l_count_task  PLS_INTEGER;
        l_count_templ_hist PLS_INTEGER;
        l_count_task_hist  PLS_INTEGER;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        BEGIN
            SELECT COUNT(*)
              INTO l_count_templ
              FROM epis_pn_det_templ e;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_templ := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_templ_hist
              FROM epis_pn_det_templ_hist e;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_templ_hist := 0;
        END;
        
        BEGIN
            SELECT COUNT(*)
              INTO l_count_task
              FROM epis_pn_det_task e;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_task := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_task_hist
              FROM epis_pn_det_task_hist e;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_task_hist := 0;
        END;        
        
    
        IF (l_count_templ != l_count_task) OR (l_count_templ_hist != l_count_task_hist)
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of records in the: epis_pn_det_templ table: ' || l_count_templ || 
                      ' epis_pn_det_task: ' || l_count_task || ' epis_pn_det_templ_hist: ' || l_count_templ_hist ||
                      ' epis_pn_det_templ_task: ' || l_count_task_hist);
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


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 18/Ago/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
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
        l_count_templ PLS_INTEGER;
        l_count_task  PLS_INTEGER;
        l_count_templ_hist PLS_INTEGER;
        l_count_task_hist  PLS_INTEGER;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        BEGIN
            SELECT COUNT(*)
              INTO l_count_templ
              FROM epis_pn_det_templ e;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_templ := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_templ_hist
              FROM epis_pn_det_templ_hist e;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_templ_hist := 0;
        END;
        
        BEGIN
            SELECT COUNT(*)
              INTO l_count_task
              FROM epis_pn_det_task e;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_task := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_task_hist
              FROM epis_pn_det_task_hist e;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_task_hist := 0;
        END;        
        
    
        IF (l_count_templ != l_count_task) OR (l_count_templ_hist != l_count_task_hist)
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of records in the: epis_pn_det_templ table: ' || l_count_templ || 
                      ' epis_pn_det_task: ' || l_count_task || ' epis_pn_det_templ_hist: ' || l_count_templ_hist ||
                      ' epis_pn_det_templ_task: ' || l_count_task_hist);
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
