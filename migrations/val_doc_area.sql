
-- CHANGED BY: Ant�nio Neto
-- CHANGE DATE: 27/04/2011 10:55
-- CHANGE REASON: [ALERT-174852] Fill the field doc_area.code_doc_area - INP - H&P import screen - Assessment tools - No descriptives available (only registration date/time).

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
        l_num_not_migrated PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        BEGIN
            SELECT COUNT(1)
              INTO l_num_not_migrated
                   FROM doc_area da
                  WHERE da.code_doc_area IS NULL
                     OR da.code_doc_area <> 'DOC_AREA.CODE_DOC_AREA.' || da.id_doc_area;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF (l_num_not_migrated IS NOT NULL AND l_num_not_migrated > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON DOC_AREA.CODE_DOC_AREA MIGRATION. NOT migrated ' || l_num_not_migrated || ' IDs.');
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

-- CHANGE END: Ant�nio Neto