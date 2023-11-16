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
        e_has_findings EXCEPTION;
        l_aux_count  PLS_INTEGER;
        l_id_episode episode.id_episode%TYPE;
        l_parent     epis_mtos_score.id_epis_mtos_score%TYPE;
    
        CURSOR c_episode IS
            SELECT DISTINCT ems.id_episode
              FROM alert.epis_mtos_score ems;
    
        CURSOR c_ems(c_id_episode IN episode.id_episode%TYPE) IS
            SELECT id_parent
              FROM (SELECT (SELECT MAX(ems2.id_epis_mtos_score) id_parent
                              FROM epis_mtos_score ems2
                             WHERE ems2.id_episode = ems.id_episode
                               AND ems2.dt_create < ems.dt_create) id_parent,
                           ems.*
                      FROM epis_mtos_score ems
                     WHERE ems.id_episode = c_id_episode
                     ORDER BY ems.id_episode, ems.dt_create DESC) t
             WHERE t.id_parent IS NOT NULL;
    
    BEGIN
    
        /* Initializations */
    
        /* Data validation */
        OPEN c_episode;
        LOOP
        
            FETCH c_episode
                INTO l_id_episode;
            EXIT WHEN c_episode%NOTFOUND;
        
            OPEN c_ems(l_id_episode);
            LOOP
                FETCH c_ems
                    INTO l_parent;
                EXIT WHEN c_ems%NOTFOUND;
            
                SELECT COUNT(*)
                  INTO l_aux_count
                  FROM epis_mtos_score ems
                 WHERE ems.id_epis_mtos_score = l_parent
                   AND ems.flg_status = 'A';
            
                IF l_aux_count > 0
                THEN
                    /* use exception raising to treat each finding: */
                    RAISE e_has_findings;
                END IF;
            
            END LOOP;
        
            CLOSE c_ems;
        
        END LOOP;
    
        CLOSE c_episode;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('EPIS_MTOS_SCORE WITH MORE THEN ONE ACTIVE EVALUATION');
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
