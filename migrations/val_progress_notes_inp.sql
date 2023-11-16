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
        l_counct_ch PLS_INTEGER;
        l_count_pn  PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT COUNT(1)
          INTO l_counct_ch
          FROM complete_history ch
          JOIN episode e
            ON e.id_episode = ch.id_episode
          JOIN institution i
            ON i.id_institution = e.id_institution
         WHERE e.id_epis_type = 5
           AND ch.long_text is not null
           AND ch.flg_status IN ('I', 'A', 'O')
           AND i.id_market <> 2;
    
        SELECT COUNT(1)
          INTO l_count_pn
          FROM (SELECT epn.id_epis_pn
                  FROM epis_pn epn
                  JOIN episode e
                    ON e.id_episode = epn.id_episode
                  JOIN institution i
                    ON i.id_institution = e.id_institution
                 WHERE e.id_epis_type = 5
                   AND epn.flg_status = 'M'
									 and epn.id_pn_note_type = 2
                   AND i.id_market <> 2
                UNION ALL
                SELECT eph.id_epis_pn
                  FROM epis_pn_hist eph
                  JOIN episode e
                    ON e.id_episode = eph.id_episode
                  JOIN institution i
                    ON i.id_institution = e.id_institution
                 WHERE e.id_epis_type = 5
                   AND eph.flg_status = 'M'
									 and eph.id_pn_note_type = 2
                   AND i.id_market <> 2);
    
        IF l_count_pn < l_counct_ch
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of migrated progress notes: ' || l_count_pn ||
                      '. Nr of complete history records: ' || l_counct_ch);
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