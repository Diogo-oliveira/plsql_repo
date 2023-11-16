-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 20/12/2011 
-- CHANGE REASON: [ALERT-210979] DEMOS MX - OUT - Admission request- se preenche as áreas de Dx e lateralidade no pedido do procedimento cirúrgico dá erro.
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
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        BEGIN
            EXECUTE IMMEDIATE 'SELECT COUNT(1)          
          FROM sr_epis_interv_hist s
         WHERE s.id_diagnosis IS NOT NULL
           AND s.id_epis_diagnosis IS NULL
           AND EXISTS (SELECT *
                  FROM epis_diagnosis ed
                 WHERE ed.id_episode = s.id_episode
                   AND ed.id_diagnosis = s.id_diagnosis)'
            INTO l_count;
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                ELSE
                    l_count := 0;
                END IF;
        END;
    
        IF (l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON SR_EPIS_INTERV. NOT SR_EPIS_INTERV: ' || l_count);
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
-- CHANGE DATE: 20/12/2011 
-- CHANGE REASON: [ALERT-210979] DEMOS MX - OUT - Admission request- se preenche as áreas de Dx e lateralidade no pedido do procedimento cirúrgico dá erro.
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
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        BEGIN
            EXECUTE IMMEDIATE 'SELECT COUNT(1)          
          FROM sr_epis_interv_hist s
         WHERE s.id_diagnosis IS NOT NULL
           AND s.id_epis_diagnosis IS NULL
           AND EXISTS (SELECT *
                  FROM epis_diagnosis ed
                 WHERE ed.id_episode = s.id_episode
                   AND ed.id_diagnosis = s.id_diagnosis)'
            INTO l_count;
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
            WHEN OTHERS THEN
                IF SQLCODE <> '-904'
                THEN
                    RAISE;
                ELSE
                    l_count := 0;
                END IF;
        END;
    
        IF (l_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON SR_EPIS_INTERV. NOT SR_EPIS_INTERV: ' || l_count);
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
