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
        e_cols_num_dont_match EXCEPTION;
        e_cols_dont_match EXCEPTION;
    
        l_tbl_cols      table_varchar := table_varchar('ID_PROFILE_TEMPLATE_REQ',
                                                       'ID_INSTITUTION',
                                                       'ID_PROFILE_TEMPLATE_DEST',
                                                       'FLG_RESP_TYPE');
        l_tbl_cons_cols table_varchar;
        l_tbl_ind_cols  table_varchar;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT d.column_name BULK COLLECT
          INTO l_tbl_cons_cols
          FROM dba_cons_columns d
         WHERE d.constraint_name = 'HOP_PK'
         ORDER BY d.position;
    
        SELECT d.column_name BULK COLLECT
          INTO l_tbl_ind_cols
          FROM dba_ind_columns d
         WHERE d.index_name = 'HOP_PK'
         ORDER BY d.column_position;
    
        IF l_tbl_cols.count != l_tbl_cons_cols.count
           OR l_tbl_cols.count != l_tbl_ind_cols.count
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_cols_num_dont_match;
        END IF;
    
        FOR i IN l_tbl_cols.first .. l_tbl_cols.last
        LOOP
            IF l_tbl_cols(i) != l_tbl_cons_cols(i)
               OR l_tbl_cols(i) != l_tbl_ind_cols(i)
            THEN
                RAISE e_cols_dont_match;
            END IF;
        END LOOP;
    
    EXCEPTION
        WHEN e_cols_num_dont_match THEN
            log_error('NUMBER OF COLUMNS IN PK AND INDEX COLUMNS DON''T MATCH.');
            /* in the end call announce_error to warn the installation script */
            announce_error;
        WHEN e_cols_dont_match THEN
            log_error('COLUMNS POSITION OR NAME DON''T MATCH IN PK AND INDEX.');
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
