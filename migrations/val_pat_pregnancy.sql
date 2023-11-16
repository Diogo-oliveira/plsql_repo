-- CHANGED BY: José Silva
-- CHANGE DATE: 06/06/2011 11:52
-- CHANGE REASON: [ALERT-183624] Pregnancy developments
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
        l_aux_count pls_integer;
    BEGIN
        /* Initializations */
    
        /* Data validation 1*/
        SELECT count(*)
          into l_aux_count
          FROM pat_pregnancy p
         WHERE p.dt_init_pregnancy IS NULL
           AND p.flg_type = 'C';
    
        IF l_aux_count != 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;

    EXCEPTION
        WHEN e_has_findings THEN
            log_error('PAT_PREGNANCY TABLE: INVALID RECORDS!!');
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
-- CHANGE END: José Silva