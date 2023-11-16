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
        l_aux_count PLS_INTEGER;

        e_already_dropped EXCEPTION;

				PRAGMA EXCEPTION_INIT(e_already_dropped, -904);
    BEGIN
        /* Initializations */
    
        /* Data validation */
        EXECUTE IMMEDIATE --
				'SELECT COUNT(*)
          FROM (SELECT 1
                  FROM epis_comp_detail ecd
                 WHERE ecd.id_context IS NOT NULL
                   AND ecd.id_context_new != to_char(ecd.id_context))'
			  INTO l_aux_count;
    
        IF l_aux_count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('Content of columns ID_CONTEXT and ID_CONTEXT_NEW differ.');
            /* in the end call announce_error to warn the installation script */
            announce_error;
				WHEN e_already_dropped THEN
				    dbms_output.put_line('Migration script has already been run in the past.');
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
