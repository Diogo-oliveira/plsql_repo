-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 15-Jul-2011
-- CHANGE REASON: ALERT-82988 [Assessement tools]: Possibility to calculate partial scores
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
        l_not_migrated table_number;
        l_flg_type_x CONSTANT epis_diagnosis.flg_type%TYPE := 'X';
        l_error VARCHAR2(4000);
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT eb.id_epis_documentation BULK COLLECT
          INTO l_not_migrated
          FROM epis_documentation     eb,
               epis_documentation_det ebd,
               documentation          d,
               doc_element            de,
               doc_component          dc,
               doc_element_crit       decr,
               doc_criteria           dcr,
               scales_doc_value       sdv,
               scales                 s,
               episode                epi,
               doc_area               da,
               summary_page_section   sps
         WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
           AND eb.id_episode = epi.id_episode
           AND d.id_documentation(+) = ebd.id_documentation
           AND de.id_doc_element = ebd.id_doc_element
           AND d.id_doc_component = dc.id_doc_component(+)
           AND dc.flg_available(+) = 'Y'
           AND d.flg_available(+) = 'Y'
           AND ebd.id_doc_element_crit = decr.id_doc_element_crit
           AND decr.id_doc_criteria = dcr.id_doc_criteria
           AND sdv.id_doc_element = de.id_doc_element
           AND s.id_scales = sdv.id_scales
           AND eb.id_doc_area = da.id_doc_area
           AND sps.id_doc_area = da.id_doc_area
           AND sps.id_summary_page = 34
           AND NOT EXISTS (SELECT 1
                  FROM epis_scales_score ess
                 WHERE ess.id_epis_documentation = eb.id_epis_documentation
                UNION ALL
                SELECT 1
                  FROM epis_scales_score_hist ess
                 WHERE ess.id_epis_documentation = eb.id_epis_documentation)
         GROUP BY eb.id_episode,
                  eb.id_epis_documentation,
                  eb.dt_creation_tstz,
                  sdv.id_scales,
                  eb.id_professional,
                  eb.dt_last_update_tstz,
                  eb.flg_status;
    
        IF l_not_migrated IS NOT NULL
           AND l_not_migrated.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            l_error := 'NOT MIGRATED EPIS DOCUMENTATION SCORES. ID_EPIS_DOCUMENTATIONS: ';
            IF (l_not_migrated IS NOT NULL AND l_not_migrated.exists(1))
            THEN
                FOR i IN 1 .. l_not_migrated.count
                LOOP
                    l_error := l_error || l_not_migrated(i) || ' ';
                END LOOP;
            END IF;
        
            log_error(l_error);
        
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
-- CHANGE END: Alexandre Santos
