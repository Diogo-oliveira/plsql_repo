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
        e_has_findings_no_pat EXCEPTION;
        l_aux_count_no_qtt PLS_INTEGER;
        l_count_no_pat     PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
    
        SELECT COUNT(*)
          INTO l_aux_count_no_qtt
          FROM epis_hidrics_det_ftxt hftxt
          JOIN epis_hidrics eh
            ON eh.id_epis_hidrics = hftxt.id_epis_hidrics
          JOIN episode e
            ON e.id_episode = eh.id_episode
         WHERE e.id_patient <> hftxt.id_patient;
    
        IF l_aux_count_no_qtt > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
        SELECT COUNT(*)
          INTO l_count_no_pat
          FROM epis_hidrics_det_ftxt hftxt
         WHERE hftxt.id_patient IS NULL;
    
        IF l_count_no_pat > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings_no_pat;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of registries in epis_hidrics_det_ftxt with id_patient different from the episode.id_patient: ' ||
                      l_aux_count_no_qtt || '. ');
            /* in the end call announce_error to warn the installation script */
            announce_error;
        
        WHEN e_has_findings_no_pat THEN
            log_error('BAD VALUE: Nr of registries in epis_hidrics_det_ftxt without id_patient: ' || l_count_no_pat || '. ');
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
