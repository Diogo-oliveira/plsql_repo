-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 01/03/2012
-- CHANGE REASON: [ALERT-166586] Current Visit
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
        l_count_hist PLS_INTEGER;
        l_count_work PLS_INTEGER;
        l_count      PLS_INTEGER;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(1)
          INTO l_count_hist
          FROM epis_pn_det_task_hist e
         WHERE e.id_task_type = 42
           AND e.id_task = (SELECT ph.id_pat_ph_ft
                              FROM pat_past_hist_ft_hist ph
                             WHERE ph.id_pat_ph_ft_hist = e.id_task);
    
        SELECT COUNT(1)
          INTO l_count_work
          FROM epis_pn_det_task_work e
         WHERE e.id_task_type = 42
           AND e.id_task = (SELECT ph.id_pat_ph_ft
                              FROM pat_past_hist_ft_hist ph
                             WHERE ph.id_pat_ph_ft_hist = e.id_task);
    
        SELECT COUNT(1)
          INTO l_count
          FROM epis_pn_det_task e
         WHERE e.id_task_type = 42
           AND e.id_task = (SELECT ph.id_pat_ph_ft
                              FROM pat_past_hist_ft_hist ph
                             WHERE ph.id_pat_ph_ft_hist = e.id_task);
    
        IF (l_count_hist > 0 OR l_count_work > 0 OR l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON single note past history free texts task type. l_count_hist: ' || l_count_hist ||
                      ' l_count_work: ' || l_count_work || ' l_count: ' || l_count);
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
