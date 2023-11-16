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
        l_count PLS_INTEGER := 0;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(1)
          INTO l_count
          FROM epis_pn_det_task epdt
          JOIN epis_pn_det epd
            ON epd.id_epis_pn_det = epdt.id_epis_pn_det
         WHERE epd.id_pn_data_block = 143
           AND epdt.table_position IS NULL;
    
        IF (l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR Progress notes table ranks migration: ' || l_count);
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


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 30/Aug/2012
-- CHANGE REASON: ALERT-239068 Current visit: Vital signs table is not sorted by the rank of the vital signs (v2 view)
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
        l_count PLS_INTEGER := 0;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(1)
          INTO l_count
          FROM alert.epis_pn_det_task epdt
          JOIN alert.epis_pn_det epd
            ON epd.id_epis_pn_det = epdt.id_epis_pn_det
         WHERE epd.id_pn_data_block = 143
           AND epdt.table_position IS NULL;
    
        IF (l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ORA- ERROR Progress notes table ranks migration: ' || l_count);
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
-- CHANGED END: Sofia Mendes


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 30/Aug/2012
-- CHANGE REASON: ALERT-239068 Current visit: Vital signs table is not sorted by the rank of the vital signs (v2 view)
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
        l_count PLS_INTEGER := 0;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(1)
          INTO l_count
          FROM alert.epis_pn_det_task epdt
          JOIN alert.epis_pn_det epd
            ON epd.id_epis_pn_det = epdt.id_epis_pn_det
         WHERE epd.id_pn_data_block = 143
           AND epdt.table_position IS NULL
           AND epdt.flg_status = 'A'
           AND epd.flg_status = 'A';
    
        IF (l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR Progress notes table ranks migration: ' || l_count);
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
-- CHANGED END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 30/Aug/2012
-- CHANGE REASON: ALERT-239068 Current visit: Vital signs table is not sorted by the rank of the vital signs (v2 view)
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
        l_count PLS_INTEGER := 0;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(1)
          INTO l_count
          FROM alert.epis_pn_det_task epdt
          JOIN alert.epis_pn_det epd
            ON epd.id_epis_pn_det = epdt.id_epis_pn_det
          JOIN vital_sign_read v
            ON v.id_vital_sign_read = epdt.id_task
         WHERE epd.id_pn_data_block = 143
           AND epdt.table_position IS NULL
           AND epdt.flg_status = 'A'
           AND epd.flg_status = 'A';
    
        IF (l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR Progress notes table ranks migration: ' || l_count);
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
-- CHANGED END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 30/Aug/2012
-- CHANGE REASON: ALERT-239068 Current visit: Vital signs table is not sorted by the rank of the vital signs (v2 view)
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
        l_count PLS_INTEGER := 0;
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(1)
          INTO l_count
          FROM alert.epis_pn_det_task epdt
          JOIN alert.epis_pn_det epd
            ON epd.id_epis_pn_det = epdt.id_epis_pn_det
          JOIN vital_sign_read v
            ON v.id_vital_sign_read = epdt.id_task
         WHERE epd.id_pn_data_block = 143
           AND epdt.table_position IS NULL
           AND epdt.flg_status = 'A'
           AND epd.flg_status = 'A';
    
        IF (l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ORA-ERROR Progress notes table ranks migration: ' || l_count);
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
-- CHANGED END: Sofia Mendes
