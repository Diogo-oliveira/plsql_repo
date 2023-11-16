-- CHANGED BY: Sofia Mendes
-- CHANGE REASON: ALERT-69406 Single page note for Discharge Summary
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
        l_count_disch_sum PLS_INTEGER;
        l_count_pn        PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT COUNT(1)
          INTO l_count_disch_sum
          FROM (SELECT pk_date_utils.dt_chr_date_hour_tsz(i_lang => nvl(il.id_language, 2),
                                                          i_date => pdn.dt_creation,
                                                          i_prof => profissional(pdn.id_professional,
                                                                                 e.id_institution,
                                                                                 ei.id_software)) date_note
                
                  FROM phy_discharge_notes pdn
                 INNER JOIN episode e
                    ON pdn.id_episode = e.id_episode
                 INNER JOIN epis_info ei
                    ON e.id_episode = ei.id_episode
                  LEFT JOIN institution_language il
                    ON e.id_institution = il.id_institution
                 WHERE pdn.flg_status = 'A')
         WHERE date_note IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_count_pn
          FROM epis_pn epn
         WHERE epn.flg_status = 'M'
           AND epn.id_pn_note_type = 13;
    
        IF l_count_pn < l_count_disch_sum
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('BAD VALUE: Nr of migrated discharge summary single pages: ' || l_count_pn ||
                      '. Nr of discharge summary records: ' || l_count_disch_sum);
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
