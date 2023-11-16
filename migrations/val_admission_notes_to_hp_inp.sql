-- CHANGED BY: ANTONIO.NETO
-- CHANGE DATE: 20/Mar/2012 
-- CHANGE REASON: [ALERT-166586] EDIS restructuring - Present Illness / Current visit
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
        l_count_anamnesis PLS_INTEGER;
        l_count_pn        PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT COUNT(1)
          INTO l_count_anamnesis
          FROM epis_anamnesis ea
         INNER JOIN episode e ON ea.id_episode = e.id_episode
                             AND e.id_epis_type = 5
         INNER JOIN epis_info ei ON e.id_episode = ei.id_episode
         INNER JOIN institution i ON e.id_institution = i.id_institution
                                 AND i.id_market <> 2
         WHERE ea.flg_status = 'A'
           AND ea.flg_type = 'C';
    
        SELECT COUNT(1)
          INTO l_count_pn
          FROM epis_pn epn
          JOIN episode e ON e.id_episode = epn.id_episode
          JOIN institution i ON i.id_institution = e.id_institution
         WHERE e.id_epis_type = 5
           AND epn.flg_status = 'M'
           AND epn.id_pn_note_type = 8
           AND i.id_market <> 2;
    
        IF l_count_pn < l_count_anamnesis
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of migrated progress notes: ' || l_count_pn ||
                      '. Nr of complete anamnesis records: ' || l_count_anamnesis);
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

-- CHANGE END: ANTONIO.NETO