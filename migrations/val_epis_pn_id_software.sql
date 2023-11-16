-- CHANGED BY: Anna Kurowska
-- CHANGE DATE: 04/02/2013
-- CHANGE REASON: [ALERT-250386] Progress notes error
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
        SELECT *
          FROM alertlog.tlog
         WHERE lsection = ''MIGRATION''
         ORDER BY 2 DESC, 3 DESC, 1 DESC;
         ');
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
        l_num_not_migrated_hist PLS_INTEGER;
    BEGIN
        /* Initializations */
   
        /* Data validation */
        BEGIN
        SELECT COUNT(1)
           INTO l_num_not_migrated 
           FROM epis_pn ep where ep.id_software is null;  
        EXCEPTION
            WHEN no_data_found THEN
                NULL;            
        END;
        
        BEGIN
        SELECT COUNT(1)
           INTO l_num_not_migrated_hist
           FROM epis_pn_hist eph where eph.id_software is null;  
        EXCEPTION
            WHEN no_data_found THEN
                NULL;            
        END;   

        IF ((l_num_not_migrated IS NOT NULL AND l_num_not_migrated > 0) OR (l_num_not_migrated_hist IS NOT NULL AND l_num_not_migrated_hist > 0))
        THEN
            RAISE e_has_findings;
        END IF;
   
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON EPIS_PN.ID_SOFTWARE. NOT migrated EPIS_PN: ' || l_num_not_migrated || ', EPIS_PN_HIST: ' || l_num_not_migrated_hist);
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
--CHANGE END: Anna Kurowska
