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
        l_aux_count PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(*)
          INTO l_aux_count
          FROM (SELECT 1
                  FROM discharge d
                  JOIN episode e ON e.id_episode = d.id_episode
                  JOIN discharge_hist dh ON dh.id_discharge = d.id_discharge
                  JOIN discharge_detail_hist ddh ON ddh.id_discharge_hist = dh.id_discharge_hist
                  JOIN disch_reas_dest drd ON drd.id_disch_reas_dest = dh.id_disch_reas_dest
                  JOIN discharge_reason dr ON dr.id_discharge_reason = drd.id_discharge_reason
                  JOIN profile_disch_reason pdr ON pdr.id_discharge_reason = drd.id_discharge_reason
                                               AND pdr.id_institution = e.id_institution
                                               AND pdr.id_profile_template = dh.id_profile_template
                 WHERE ddh.flg_pat_condition = 'U'
                 ORDER BY dh.dt_created_hist DESC);
    
        IF l_aux_count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('Continuous to exist flg U in american discharge.');
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
