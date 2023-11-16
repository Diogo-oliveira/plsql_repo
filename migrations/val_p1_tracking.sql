-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2011-DEV-22
-- CHANGED REASON: ALERT-194845

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
        l_num_not_migrated PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        BEGIN
        
            SELECT COUNT(1)
              INTO l_num_not_migrated
              FROM (SELECT t.id_external_request,
                           lag(t.id_external_request, 1) over(ORDER BY t.id_external_request, t.dt_tracking_tstz) prev_id_ext_req,
                           t.id_tracking,
                           t.ext_req_status,
                           lag(t.ext_req_status, 1) over(ORDER BY t.id_external_request, t.dt_tracking_tstz) prev_flg_status,
                           flg_subtype,
                           id_workflow_action
                      FROM p1_tracking t
                     WHERE t.flg_type NOT IN ('R', 'U', 'T')
                     ORDER BY t.id_external_request, t.dt_tracking_tstz) tab1
             WHERE ext_req_status = 'A'
               AND decode(tab1.prev_id_ext_req, tab1.id_external_request, tab1.prev_flg_status, NULL) IN ('S', 'M')
               AND (flg_subtype IS NULL OR flg_subtype != 'C');
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF (l_num_not_migrated IS NOT NULL AND l_num_not_migrated > 0)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON P1_TRACKING MIGRATION of field flg_subtype. NOT migrated ' || l_num_not_migrated || ' IDs.');
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
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2012-JUN-01
-- CHANGED REASON: ALERT-230846
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
        l_error VARCHAR2(32737);
    
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
    
        -- intermediate tracking
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT 1
                  FROM p1_tracking t
                  JOIN p1_external_request p
                    ON p.id_external_request = t.id_external_request
                 WHERE t.flg_type NOT IN ('R', 'U')
                   AND t.id_dep_clin_serv IS NOT NULL
                   AND t.id_speciality IS NULL
                   AND (p.id_workflow IN (1, 2, 3, 4, 8) OR p.id_workflow IS NULL)
                   AND p.id_speciality IS NOT NULL
                   AND p.flg_type = 'C'
                UNION ALL
                -- ext_req_status=N
                SELECT 1
                  FROM (SELECT t1.id_tracking,
                               t1.id_speciality,
                               t1.id_external_request,
                               t1.ext_req_status,
                               row_number() over(PARTITION BY t1.id_external_request ORDER BY t1.dt_tracking_tstz ASC) my_row
                          FROM p1_tracking t1
                         WHERE t1.flg_type = 'S'
                           AND t1.ext_req_status = 'N') t
                  JOIN p1_external_request p
                    ON p.id_external_request = t.id_external_request
                 WHERE t.my_row = 1
                   AND t.id_speciality IS NULL
                   AND (p.id_workflow IN (1, 2, 3, 4, 8) OR p.id_workflow IS NULL)
                   AND p.id_speciality IS NOT NULL
                   AND p.flg_type = 'C'
                UNION ALL
                -- ext_req_status=O
                SELECT 1
                  FROM (SELECT t1.id_tracking,
                               t1.id_speciality,
                               t1.id_external_request,
                               t1.ext_req_status,
                               row_number() over(PARTITION BY t1.id_external_request ORDER BY t1.dt_tracking_tstz ASC) my_row
                          FROM p1_tracking t1
                         WHERE t1.flg_type = 'S'
                           AND t1.ext_req_status = 'O') t
                  JOIN p1_external_request p
                    ON p.id_external_request = t.id_external_request
                 WHERE t.my_row = 1
                   AND t.id_speciality IS NULL
                   AND (p.id_workflow IN (1, 2, 3, 4, 8) OR p.id_workflow IS NULL)
                   AND p.id_speciality IS NOT NULL
                   AND p.flg_type = 'C');
    
        IF l_count != 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            log_error('There are records in table P1_TRACKING that were not migrated: ' || l_count ||
                      ' records. Please execute this queries in order to validate migration results:');
            log_error('SELECT *
  FROM p1_tracking t
  JOIN p1_external_request p
    ON p.id_external_request = t.id_external_request
 WHERE t.flg_type NOT IN (''R'', ''U'')
   AND t.id_dep_clin_serv IS NOT NULL
	 AND t.id_speciality IS NULL
	 AND (p.id_workflow IN (1,2,3,4,8) or p.id_workflow IS NULL)
   AND p.id_speciality IS NOT NULL
	 AND p.flg_type = ''C'';');
        
            log_error('SELECT *
  FROM (SELECT t1.id_tracking,
               t1.id_speciality,
               t1.id_external_request,
               t1.ext_req_status,
               row_number() over(PARTITION BY t1.id_external_request ORDER BY t1.dt_tracking_tstz ASC) my_row
          FROM p1_tracking t1
         WHERE t1.flg_type = ''S''
           AND t1.ext_req_status = ''N'') t
  JOIN p1_external_request p
    ON p.id_external_request = t.id_external_request
 WHERE t.my_row = 1
   AND t.id_speciality IS NULL
	 AND (p.id_workflow IN (1,2,3,4,8) or p.id_workflow IS NULL)
	 AND p.id_speciality IS NOT NULL
	 AND p.flg_type = ''C'';');
        
            log_error('SELECT *
  FROM (SELECT t1.id_tracking,
               t1.id_speciality,
               t1.id_external_request,
               t1.ext_req_status,
               row_number() over(PARTITION BY t1.id_external_request ORDER BY t1.dt_tracking_tstz ASC) my_row
          FROM p1_tracking t1
         WHERE t1.flg_type = ''S''
           AND t1.ext_req_status = ''O'') t
  JOIN p1_external_request p
    ON p.id_external_request = t.id_external_request
 WHERE t.my_row = 1
   AND t.id_speciality IS NULL
	 AND (p.id_workflow IN (1,2,3,4,8) or p.id_workflow IS NULL)
	 AND p.id_speciality IS NOT NULL
	 AND p.flg_type = ''C'';');
        
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
-- CHANGE END: Ana Monteiro