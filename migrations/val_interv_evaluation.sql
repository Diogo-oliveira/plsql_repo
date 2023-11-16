-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 18/09/2012 17:33
-- CHANGE REASON: [ALERT-240395] 
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
        l_interv_evaluation table_varchar;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT ie.id_interv_evaluation bulk collect
        into l_interv_evaluation
  FROM interv_evaluation ie
 WHERE ie.flg_type = 'N' --NOTES
   AND ie.flg_status = 'A' --ACTIVE
   AND ie.id_episode IS NOT NULL
   AND NOT EXISTS (SELECT 1
          FROM epis_documentation ed
         WHERE ed.id_doc_area = 5097
           AND ed.id_episode = ie.id_episode
           AND ed.id_professional = ie.id_professional
           AND ed.dt_creation_tstz = ie.dt_interv_evaluation_tstz);
    
        IF l_interv_evaluation.exists(1)
           AND l_interv_evaluation.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            FOR i IN l_interv_evaluation.first .. l_interv_evaluation.last
            LOOP
            
                log_error('BAD VALUE: ' || l_interv_evaluation(i));
            END LOOP;
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
-- CHANGE END:  Nuno Neves