-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 01/04/2011 
-- CHANGE REASON: [ALERT-166051] 

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
        l_counct_ch PLS_INTEGER;
        l_count_pn  PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT COUNT(1)
          INTO l_counct_ch
          FROM task_timeline_ea tt
         WHERE tt.id_tl_task IN (10, 11);
    
        SELECT COUNT(1)
          INTO l_count_pn
          FROM task_timeline_ea ttea
         WHERE ttea.id_tl_task IN (10, 11)
           AND ttea.status_str IN ('|I|||DetailInternmentIcon|0x787864||||&', '|I|||SurgeryIcon|0x787864||||&');
    
        IF l_count_pn < l_counct_ch
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of migrated task_timeline_ea: ' || l_count_pn || '. Nr of complete records: ' ||
                      l_counct_ch);
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

-- CHANGE END: Filipe Silva
