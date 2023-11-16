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
        l_aux_count_no_item PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        BEGIN
            SELECT COUNT(*)
              INTO l_aux_count_no_item
              FROM epis_recomend e
              JOIN epis_documentation d ON d.id_episode = e.id_episode
             WHERE e.id_notes_config IN (6, 7, 9)
               AND e.flg_type = 'M'
               AND e.id_item IS NULL
               AND d.notes IS NOT NULL
               AND e.desc_epis_recomend = to_char(substr(notes, 1, 4000))
               AND d.id_doc_area IN (21, 22, 28)
               AND d.dt_creation_tstz BETWEEN e.dt_epis_recomend_tstz - INTERVAL '10' SECOND
               AND e.dt_epis_recomend_tstz +
                   INTERVAL '10' SECOND
             GROUP BY e.id_episode, e.id_epis_recomend
            HAVING COUNT(1) = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_aux_count_no_item := 0;
        END;
    
        IF l_aux_count_no_item > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of registries in epis_recommend table without id_item: ' || l_aux_count_no_item || '. ');
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
