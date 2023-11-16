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
        l_error VARCHAR2(32737);
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
    
        -- intermediate tracking
        SELECT COUNT(1)
          INTO l_count
          FROM p1_spec_dep_clin_serv
         WHERE id_dep_clin_serv IN (SELECT s.id_dep_clin_serv
                                      FROM p1_spec_dep_clin_serv s
                                     GROUP BY id_dep_clin_serv
                                    HAVING COUNT(1) = 1)
           AND flg_spec_dcs_default IS NULL;
    
        IF l_count != 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('There are records in table p1_spec_dep_clin_serv that were not migrated: ' || l_count ||
                      ' records. Please execute this query in order to validate migration results:');
            log_error('SELECT *
          FROM p1_spec_dep_clin_serv
         WHERE id_dep_clin_serv IN (SELECT s.id_dep_clin_serv
                                      FROM p1_spec_dep_clin_serv s
                                     GROUP BY id_dep_clin_serv
                                    HAVING COUNT(1) = 1)
           AND flg_spec_dcs_default IS NULL;');
        
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
