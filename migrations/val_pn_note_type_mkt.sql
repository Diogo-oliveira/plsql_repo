-- CHANGED BY: António Neto
-- CHANGE DATE: 02/01/2012
-- CHANGE REASON: [ALERT-211833] Fix findings - Solve findings identified by Technical Arq. BD
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
         WHERE lsection = '' migration ''
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
    BEGIN
        /* Initializations */
   
        /* Data validation */
        BEGIN
				   EXECUTE IMMEDIATE 'SELECT COUNT(1)
          FROM pn_note_type_mkt pnnt
         WHERE pnnt.flg_edit_after_disch <> pnnt.flg_editable_after_discharge'
            INTO l_num_not_migrated;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                END IF;
        END;
   
        IF (l_num_not_migrated IS NOT NULL AND l_num_not_migrated > 0)
        THEN
            RAISE e_has_findings;
        END IF;
   
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON PN_NOTE_TYPE_MKT.FLG_EDIT_AFTER_DISCH. NOT migrated ' || l_num_not_migrated || ' IDs.');
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
--CHANGE END: António Neto
