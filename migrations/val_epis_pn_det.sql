-- CHANGED BY: António Neto
-- CHANGE DATE: 12/Aug/2011 
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
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
        l_count_epis_pn_det             PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        BEGIN
            SELECT count(*)
						INTO l_count_epis_pn_det
                   FROM epis_pn epn
                  INNER JOIN epis_pn_det epnd ON epn.id_epis_pn = epnd.id_epis_pn
                  INNER JOIN pn_data_block pndb ON epnd.id_pn_data_block = pndb.id_pn_data_block
                                               AND pndb.flg_type = 'C'
                                               AND pndb.data_area = 'CD'
                  WHERE epnd.dt_note IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_epis_pn_det := 0;
        END;
    
        IF l_count_epis_pn_det > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of records without Date note type Det l_count_epis_pn_det: ' || l_count_epis_pn_det);
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
-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 12/Aug/2011 
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
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
        l_count_epis_pn_det             PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        BEGIN
            SELECT count(*)
						INTO l_count_epis_pn_det
                   FROM epis_pn epn
                  INNER JOIN epis_pn_det epnd ON epn.id_epis_pn = epnd.id_epis_pn
                  INNER JOIN pn_data_block pndb ON epnd.id_pn_data_block = pndb.id_pn_data_block
                                               AND pndb.flg_type = 'C'
                                               AND pndb.data_area = 'CD'
                  WHERE epnd.dt_note IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_epis_pn_det := 0;
        END;
    
        IF l_count_epis_pn_det > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of records without Date note type Det l_count_epis_pn_det: ' || l_count_epis_pn_det);
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
-- CHANGE END: António Neto

