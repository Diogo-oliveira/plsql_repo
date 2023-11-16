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
    
        CURSOR c_missing_fk IS
            SELECT *
              FROM (SELECT 'AUDIT_TYPE_TRIAGE_TYPE' tab_name,
                           'ID_TRIAGE_TYPE' col_name,
                           'TRIAGE_TYPE' parent_tab_name,
                           'ID_TRIAGE_TYPE' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'CARE_STAGE_SET_PERMISSIONS' tab_name,
                           'ID_INSTITUTION' col_name,
                           'INSTITUTION' parent_tab_name,
                           'ID_INSTITUTION' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'CO_SIGN_TASK' tab_name,
                           'ID_EPISODE' col_name,
                           'EPISODE' parent_tab_name,
                           'ID_EPISODE' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'DIAGNOSIS_CAT' tab_name,
                           'ID_CATEGORY' col_name,
                           'CATEGORY' parent_tab_name,
                           'ID_CATEGORY' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'DIAGNOSIS_CAT' tab_name,
                           'ID_DIAGNOSIS' col_name,
                           'DIAGNOSIS' parent_tab_name,
                           'ID_DIAGNOSIS' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'DISCH_REAS_DEST' tab_name,
                           'ID_DEF_DISCH_STATUS' col_name,
                           'DISCHARGE_STATUS' parent_tab_name,
                           'ID_DISCHARGE_STATUS' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'DISCH_REAS_DEST' tab_name,
                           'ID_REPORTS' col_name,
                           'REPORTS' parent_tab_name,
                           'ID_REPORTS' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'DISCHARGE_DETAIL' tab_name,
                           'ID_EPIS_DIAGNOSIS' col_name,
                           'EPIS_DIAGNOSIS' parent_tab_name,
                           'ID_EPIS_DIAGNOSIS' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'DISCHARGE_DETAIL' tab_name,
                           'ID_TRANSFER_DIAGNOSIS' col_name,
                           'DIAGNOSIS' parent_tab_name,
                           'ID_DIAGNOSIS' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'DISCHARGE_DETAIL' tab_name,
                           'ID_TRANSPORT_TYPE' col_name,
                           'TRANSPORT_TYPE' parent_tab_name,
                           'ID_TRANSPORT_TYPE' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'DISCHARGE_NOTES_FOLLOW_UP' tab_name,
                           'ID_DISCHARGE_NOTES' col_name,
                           'DISCHARGE_NOTES' parent_tab_name,
                           'ID_DISCHARGE_NOTES' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EPIS_PROF_RESP' tab_name,
                           'ID_MOVEMENT' col_name,
                           'MOVEMENT' parent_tab_name,
                           'ID_MOVEMENT' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EPIS_READMISSION' tab_name,
                           'ID_PROFESSIONAL' col_name,
                           'PROFESSIONAL' parent_tab_name,
                           'ID_PROFESSIONAL' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT' tab_name,
                           'ID_EVENT_GROUP' col_name,
                           'EVENT_GROUP' parent_tab_name,
                           'ID_EVENT_GROUP' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_GROUP' tab_name,
                           'ID_TIME_EVENT_GROUP' col_name,
                           'TIME_EVENT_GROUP' parent_tab_name,
                           'ID_TIME_EVENT_GROUP' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_GROUP_SOFT_INST' tab_name,
                           'ID_EVENT_GROUP' col_name,
                           'EVENT_GROUP' parent_tab_name,
                           'ID_EVENT_GROUP' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_GROUP_SOFT_INST' tab_name,
                           'ID_INSTITUTION' col_name,
                           'INSTITUTION' parent_tab_name,
                           'ID_INSTITUTION' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_GROUP_SOFT_INST' tab_name,
                           'ID_SOFTWARE' col_name,
                           'SOFTWARE' parent_tab_name,
                           'ID_SOFTWARE' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_MOST_FREQ' tab_name,
                           'ID_EPISODE' col_name,
                           'EPISODE' parent_tab_name,
                           'ID_EPISODE' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_MOST_FREQ' tab_name,
                           'ID_INSTITUTION_READ' col_name,
                           'INSTITUTION' parent_tab_name,
                           'ID_INSTITUTION' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_MOST_FREQ' tab_name,
                           'ID_PAT_PREGNANCY' col_name,
                           'PAT_PREGNANCY' parent_tab_name,
                           'ID_PAT_PREGNANCY' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_MOST_FREQ' tab_name,
                           'ID_PATIENT' col_name,
                           'PATIENT' parent_tab_name,
                           'ID_PATIENT' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_MOST_FREQ' tab_name,
                           'ID_PROF_READ' col_name,
                           'PROFESSIONAL' parent_tab_name,
                           'ID_PROFESSIONAL' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_MOST_FREQ' tab_name,
                           'ID_SOFTWARE_READ' col_name,
                           'SOFTWARE' parent_tab_name,
                           'ID_SOFTWARE' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'EVENT_MOST_FREQ' tab_name,
                           'ID_UNIT_MEASURE' col_name,
                           'UNIT_MEASURE' parent_tab_name,
                           'ID_UNIT_MEASURE' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'MATCH_EPIS' tab_name,
                           'ID_EPISODE' col_name,
                           'EPISODE' parent_tab_name,
                           'ID_EPISODE' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'MATCH_EPIS' tab_name,
                           'ID_PROFESSIONAL' col_name,
                           'PROFESSIONAL' parent_tab_name,
                           'ID_PROFESSIONAL' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'PROFILE_DISCH_REASON' tab_name,
                           'ID_DISCHARGE_FLASH_FILES' col_name,
                           'DISCHARGE_FLASH_FILES' parent_tab_name,
                           'ID_DISCHARGE_FLASH_FILES' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'TIME' tab_name,
                           'ID_TIME_GROUP' col_name,
                           'TIME_GROUP' parent_tab_name,
                           'ID_TIME_GROUP' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'TIME_EVENT_GROUP' tab_name,
                           'ID_EVENT_GROUP' col_name,
                           'EVENT_GROUP' parent_tab_name,
                           'ID_EVENT_GROUP' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'TIME_EVENT_GROUP' tab_name,
                           'ID_TIME_EVENT_GROUP' col_name,
                           'TIME_EVENT_GROUP' parent_tab_name,
                           'ID_TIME_EVENT_GROUP' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'TIME_EVENT_GROUP' tab_name,
                           'ID_TIME_GROUP' col_name,
                           'TIME_GROUP' parent_tab_name,
                           'ID_TIME_GROUP' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'TRIAGE_WHITE_REAS_INST' tab_name,
                           'ID_TRIAGE_WHITE_REASON' col_name,
                           'TRIAGE_WHITE_REASON' parent_tab_name,
                           'ID_TRIAGE_WHITE_REASON' parent_col_name
                      FROM dual
                    UNION ALL
                    SELECT 'WIZARD_COMP_REL' tab_name,
                           'ID_DOC_AREA' col_name,
                           'DOC_AREA' parent_tab_name,
                           'ID_DOC_AREA' parent_col_name
                      FROM dual);
    
        r_miss  c_missing_fk%ROWTYPE;
        l_sql   VARCHAR2(32767);
        l_count PLS_INTEGER;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        OPEN c_missing_fk;
        LOOP
            FETCH c_missing_fk
                INTO r_miss;
            EXIT WHEN c_missing_fk%NOTFOUND;
        
            l_sql := '' || --
                     'SELECT COUNT(*) total_rows ' || --
                     '  FROM (SELECT 1 ' || --
                     '          FROM ' || r_miss.tab_name || ' a ' || --
                     '         WHERE a.' || r_miss.col_name || ' IS NOT NULL ' || --
                     '           AND NOT EXISTS (SELECT 1 ' || --
                     '                             FROM ' || r_miss.parent_tab_name || ' b ' || --
                     '                            WHERE b.' || r_miss.parent_col_name || ' = a.' || r_miss.col_name || '))';
        
            EXECUTE IMMEDIATE l_sql
                INTO l_count;
        
            IF l_count > 0
            THEN
                /* use exception raising to treat each finding: */
                RAISE e_has_findings;
            END IF;
        
        END LOOP;
        CLOSE c_missing_fk;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('STILL EXISTS RECORDS ON ' || r_miss.tab_name || '.' || r_miss.col_name ||
                      ' THAT DOES''NT EXISTS ON ' || r_miss.parent_tab_name || '.' || r_miss.parent_col_name || '.');
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
