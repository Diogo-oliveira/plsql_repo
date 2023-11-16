-- CHANGED BY: José Silva
-- CHANGE DATE: 14/10/2010 12:19
-- CHANGE REASON: [ALERT-117834] 
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
        e_has_findings EXCEPTION;
l_aux_count pls_integer;
l_aux_count2 pls_integer;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT count(*)
  into l_aux_count
          FROM epis_recomend er
 WHERE er.flg_type = 'D';

        SELECT count(*)
  into l_aux_count2
          FROM epis_documentation ed
 WHERE ed.id_doc_area = 6710;

        IF l_aux_count <> l_aux_count2
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
log_error('INCONSISTENT DATA BETWEEN EPIS_RECOMEND AND EPIS_DOCUMENTATION.');
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

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 13/11/2011 11:40
-- CHANGE REASON: [ALERT-176957] 
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
        e_has_findings EXCEPTION;
        l_aux_count PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(*)
          INTO l_aux_count
          FROM epis_recomend er
         WHERE er.flg_type = 'N'
           AND er.flg_status IS NULL;
    
        IF l_aux_count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('CONTINUES TO HAVE NULL VALUES ON FLAG STATUS.');
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
-- CHANGE END: Alexandre santos
