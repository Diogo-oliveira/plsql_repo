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
        l_flg_type_x CONSTANT epis_diagnosis.flg_type%TYPE := 'X';
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(*)
          INTO l_aux_count
          FROM (SELECT 1
                  FROM epis_diagnosis ed
                 WHERE ed.flg_type != l_flg_type_x
                 GROUP BY ed.id_episode, ed.id_diagnosis, ed.flg_type
                HAVING COUNT(*) > 1
                 ORDER BY ed.id_episode, ed.id_diagnosis, ed.flg_type);
    
        IF l_aux_count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('STILL EXISTS MORE THEN ONE DIAGNOSIS PER EPISODE WITH THE SAME FLG_TYPE.');
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
        l_flg_type_x CONSTANT epis_diagnosis.flg_type%TYPE := 'X';
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT COUNT(*)
          INTO l_aux_count
          FROM (SELECT 1
                  FROM epis_diagnosis ed
                 WHERE ed.flg_type != l_flg_type_x
                 GROUP BY ed.id_episode, ed.id_diagnosis, ed.flg_type, ed.desc_epis_diagnosis
                HAVING COUNT(*) > 1
                 ORDER BY ed.id_episode, ed.id_diagnosis, ed.flg_type, ed.desc_epis_diagnosis);
    
        IF l_aux_count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('STILL EXISTS MORE THEN ONE DIAGNOSIS PER EPISODE WITH THE SAME FLG_TYPE.');
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
