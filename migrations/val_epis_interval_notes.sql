-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 08/11/2010 14:36
-- CHANGE REASON: [ALERT-138460] Editable areas: Make prioritary areas editable: Progress Notes (EDIS)
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
        l_aux_count  PLS_INTEGER;
        l_aux_count2 PLS_INTEGER;
        l_dt_max_ein epis_interval_notes.dt_creation_tstz%TYPE;
    BEGIN
        /* Initializations */
        SELECT MAX(nvl(ein.dt_creation_tstz, ein.adw_last_update))
          INTO l_dt_max_ein
          FROM epis_interval_notes ein;
--dbms_output.put_line('Last record in epis_interval_notes:' || to_char(l_dt_max_ein));
    
        /* Data validation */
        SELECT COUNT(*)
          INTO l_aux_count
          FROM epis_interval_notes ein;
--dbms_output.put_line('Rows in epis_interval_notes:' || l_aux_count);
    
        SELECT COUNT(*)
          INTO l_aux_count2
          FROM epis_documentation ed
         WHERE ed.id_doc_area IN (1092, 6724, 6725)
           AND ed.dt_creation_tstz <= l_dt_max_ein;
 --dbms_output.put_line('Rows in epis_documentation up to last record in epis_interval_notes:'|| l_aux_count2);
    
        IF l_aux_count <> l_aux_count2
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('INCONSISTENT DATA BETWEEN EPIS_INTERVAL_NOTES AND EPIS_DOCUMENTATION.');
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
-- CHANGE END: Ariel Machado