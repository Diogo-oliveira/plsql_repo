-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 06/Feb/2013 
-- CHANGE REASON: ALERT-226899 Progress notes migration to Recheck functionality in ALERT® EDIS 

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
    
        l_id_doc_area epis_documentation.id_doc_area%TYPE := 6746;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        BEGIN
            SELECT nvl(COUNT(1), 0)
              INTO l_count
              FROM epis_documentation ed
             INNER JOIN episode e
                ON ed.id_episode = e.id_episode
              LEFT JOIN doc_template dt
                ON ed.id_doc_template = dt.id_doc_template
             INNER JOIN epis_info ei
                ON e.id_episode = ei.id_episode
             INNER JOIN institution i
                ON e.id_institution = i.id_institution
              LEFT OUTER JOIN institution_language il
                ON i.id_institution = il.id_institution
             WHERE ed.id_doc_area = 1092
               AND pk_date_utils.dt_chr_date_hour_tsz(i_lang => nvl(il.id_language, 2),
                                                      i_date => nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz),
                                                      i_prof => profissional(ed.id_professional,
                                                                             e.id_institution,
                                                                             ei.id_software)) IS NOT NULL
                  
               AND NOT EXISTS (SELECT 1
                      FROM epis_pn_det_task epdt
                      JOIN epis_pn_det epd
                        ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                      JOIN epis_pn epn
                        ON epn.id_epis_pn = epd.id_epis_pn
                     WHERE epdt.id_task_type = 36
                       AND epn.id_pn_note_type = 11
                       AND epn.flg_status IN ('M', 'C'));
        
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
        END;
    
        IF l_count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of edis progress notes not migrated ' || l_count);
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

-- CHANGE END: Sofia.Mendes
