-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 13/05/2011
-- CHANGE REASON: [ALERT-178899]

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
        l_count_ss  PLS_INTEGER;
        l_count_pta PLS_INTEGER;
        l_count_gt  PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT COUNT(1)
          INTO l_count_ss
          FROM sys_shortcut
         WHERE id_sys_shortcut IN (167324, 167321, 167322, 167323);
    
        SELECT COUNT(1)
          INTO l_count_pta
          FROM profile_templ_access
         WHERE id_sys_shortcut IN (167324, 167321, 167322, 167323);
    
        SELECT COUNT(1)
          INTO l_count_gt
          FROM grid_task
         WHERE regexp_like(supplies, '^167324|')
            OR regexp_like(supplies, '^167321|')
            OR regexp_like(supplies, '^167322|')
            OR regexp_like(supplies, '^167323|');
    
        IF l_count_ss + l_count_pta + l_count_gt > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of sys_shortcut records needing migration: ' || l_count_ss ||
                      '. Nr of profile_templ_access records needing migration: ' || l_count_pta ||
                      '. Nr of grid_task records needing migration: ' || l_count_gt);
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

-- CHANGE END: Fábio Oliveira
