-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 11/01/2011 17:03
-- CHANGE REASON: [ALERT-154287] Issue Replication: NL Hand-off problems
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
        e_has_findings2 EXCEPTION;
        l_aux_count PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(*)
          INTO l_aux_count
          FROM (SELECT epr.id_epis_prof_resp
                  FROM epis_prof_resp epr
                  JOIN epis_info ei ON ei.id_episode = epr.id_episode
                 WHERE ei.id_software = 1
                   AND NOT EXISTS (SELECT *
                          FROM epis_multi_prof_resp empr
                         WHERE empr.id_epis_prof_resp = epr.id_epis_prof_resp
                           AND empr.flg_resp_type = 'O'));
    
        IF l_aux_count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('STILL EXISTS EPISODE RESPONSIBLES IN OUTP.');
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
-- CHANGE END: Alexandre Santos