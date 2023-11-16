-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/10/2013 
-- CHANGE REASON: [ALERT-262351 INP Nurse simplified profile
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
            SELECT COUNT(1)
              INTO l_count
              FROM epis_pn_det e
              JOIN epis_pn epn
                ON epn.id_epis_pn = e.id_epis_pn
              JOIN episode epi
                ON epi.id_episode = epn.id_episode
              LEFT OUTER JOIN institution_language il
                ON epi.id_institution = il.id_institution
             WHERE e.id_pn_data_block = 48
               AND e.flg_status = 'A'
               AND NOT EXISTS (SELECT 1
                      FROM epis_anamnesis ea
                     WHERE dbms_lob.compare(ea.desc_epis_anamnesis, e.pn_note) = 0
                       AND ea.id_episode = epn.id_episode
                       AND ea.dt_epis_anamnesis_tstz = e.dt_pn);
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
            log_error('ERROR ON mig h and p chief complaint. l_count: ' || l_count);
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
