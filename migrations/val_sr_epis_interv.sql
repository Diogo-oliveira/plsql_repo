-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/05/2011 
-- CHANGE REASON: [ALERT-181163]: Some fields of ALERT.SR_EPIS_INTERV not always filled 
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
        l_count_dcs_ids      PLS_INTEGER;
        l_count_dcs_ids_hist PLS_INTEGER;
    
        l_start_count PLS_INTEGER := 0;
        l_end_count   PLS_INTEGER := 0;
    
        l_not_migrated_ids_dcs VARCHAR2(32000) := NULL;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(1)
          INTO l_start_count
          FROM sr_surgery_time_det s
          JOIN sr_epis_interv sr
            ON sr.id_episode_context = s.id_episode
          JOIN sr_surgery_time sst
            ON sst.id_sr_surgery_time = s.id_sr_surgery_time
         WHERE sr.dt_interv_start_tstz IS NULL
           AND sr.flg_status <> 'C'
           AND sst.flg_type = 'IC'
           AND s.flg_status = 'A';
    
        SELECT COUNT(1)
          INTO l_end_count
          FROM sr_surgery_time_det s
          JOIN sr_epis_interv sr
            ON sr.id_episode_context = s.id_episode
          JOIN sr_surgery_time sst
            ON sst.id_sr_surgery_time = s.id_sr_surgery_time
         WHERE sr.dt_interv_end_tstz IS NULL
           AND sr.flg_status <> 'C'
           AND sst.flg_type = 'FC'
           AND s.flg_status = 'A';
    
        IF (l_start_count > 0 OR l_end_count > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ORA-2001: ERROR ON SR_EPIS_INTERV MIGRATION. NOT migrated dt_interv_start: ' || l_start_count ||
                      '. NOT migrated dt_interv_end: ' || l_end_count);
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
