-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/Jul/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
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
        l_count_epis_pn             PLS_INTEGER;
        l_count_epis_pn_hist        PLS_INTEGER;
        l_count_epis_pn_work        PLS_INTEGER;
        l_count_pn_button_mkt       PLS_INTEGER;
        l_count_pn_button_soft_inst PLS_INTEGER;
        l_count_pn_dblock_soft_inst PLS_INTEGER;
        l_count_pn_dblock_mkt       PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        BEGIN
            SELECT COUNT(*)
              INTO l_count_epis_pn
              FROM epis_pn e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_epis_pn := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_epis_pn_hist
              FROM epis_pn_hist e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_epis_pn_hist := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_epis_pn_work
              FROM epis_pn_work e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_epis_pn_work := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_pn_button_mkt
              FROM pn_button_mkt e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_pn_button_mkt := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_pn_button_soft_inst
              FROM pn_button_soft_inst e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_pn_button_soft_inst := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_pn_dblock_soft_inst
              FROM pn_dblock_soft_inst e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_pn_dblock_soft_inst := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_pn_dblock_mkt
              FROM pn_dblock_mkt e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_pn_dblock_mkt := 0;
        END;
    
        IF l_count_epis_pn > 0
           OR l_count_epis_pn_hist > 0
           OR l_count_epis_pn_work > 0
           OR l_count_pn_button_mkt > 0
           OR l_count_pn_button_soft_inst > 0
           OR l_count_pn_dblock_soft_inst > 0
           OR l_count_pn_dblock_mkt > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of records without note type l_count_epis_pn: ' || l_count_epis_pn ||
                      ' l_count_epis_pn_hist: ' || l_count_epis_pn || ' l_count_epis_pn_work: ' || l_count_epis_pn ||
                      ' l_count_pn_button_mkt: ' || l_count_pn_button_mkt || ' l_count_pn_button_soft_inst: ' ||
                      l_count_pn_button_soft_inst || ' l_count_pn_dblock_soft_inst: ' || l_count_pn_dblock_soft_inst ||
                      ' l_count_pn_dblock_mkt: ' || l_count_pn_dblock_mkt);
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
-- CHANGE DATE: 26/Jul/2011 
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
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
        l_count_epis_pn             PLS_INTEGER;
        l_count_epis_pn_hist        PLS_INTEGER;
        l_count_epis_pn_work        PLS_INTEGER;
        l_count_pn_button_mkt       PLS_INTEGER;
        l_count_pn_button_soft_inst PLS_INTEGER;
        l_count_pn_dblock_soft_inst PLS_INTEGER;
        l_count_pn_dblock_mkt       PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        BEGIN
            SELECT COUNT(*)
              INTO l_count_epis_pn
              FROM epis_pn e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_epis_pn := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_epis_pn_hist
              FROM epis_pn_hist e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_epis_pn_hist := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_epis_pn_work
              FROM epis_pn_work e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_epis_pn_work := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_pn_button_mkt
              FROM pn_button_mkt e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_pn_button_mkt := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_pn_button_soft_inst
              FROM pn_button_soft_inst e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_pn_button_soft_inst := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_pn_dblock_soft_inst
              FROM pn_dblock_soft_inst e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_pn_dblock_soft_inst := 0;
        END;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_count_pn_dblock_mkt
              FROM pn_dblock_mkt e
             WHERE e.id_pn_note_type IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_count_pn_dblock_mkt := 0;
        END;
    
        IF l_count_epis_pn > 0
           OR l_count_epis_pn_hist > 0
           OR l_count_epis_pn_work > 0
           OR l_count_pn_button_mkt > 0
           OR l_count_pn_button_soft_inst > 0
           OR l_count_pn_dblock_soft_inst > 0
           OR l_count_pn_dblock_mkt > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of records without note type l_count_epis_pn: ' || l_count_epis_pn ||
                      ' l_count_epis_pn_hist: ' || l_count_epis_pn || ' l_count_epis_pn_work: ' || l_count_epis_pn ||
                      ' l_count_pn_button_mkt: ' || l_count_pn_button_mkt || ' l_count_pn_button_soft_inst: ' ||
                      l_count_pn_button_soft_inst || ' l_count_pn_dblock_soft_inst: ' || l_count_pn_dblock_soft_inst ||
                      ' l_count_pn_dblock_mkt: ' || l_count_pn_dblock_mkt);
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
