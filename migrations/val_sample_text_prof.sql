-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 12/11/2012 12:29
-- CHANGE REASON: [ALERT-244131] 
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
        l_count PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT s.id_professional, s.title_sample_text_prof
                  FROM sample_text_prof s
                 WHERE id_sample_text_type = 132
                MINUS
                SELECT s.id_professional, s.title_sample_text_prof
                  FROM sample_text_prof s
                 WHERE id_sample_text_type = 3240074);
    
        IF (l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON sample_text_prof MIGRATION / id_sample_text_type = 132. NOT migrated ' || l_count ||
                      ' IDs.');
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
-- CHANGE END: Ana Monteiro