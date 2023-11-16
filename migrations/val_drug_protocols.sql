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
        l_drug_protocols_ids table_varchar;
        c                    NUMBER;
    BEGIN
        /* Initializations */
        SELECT COUNT(1)
          INTO c
          FROM all_tab_cols atc
         WHERE lower(atc.table_name) = 'drug_protocols'
           AND lower(atc.column_name) = 'id_drug_duplicate'
           AND lower(atc.owner) = 'alert';
    
        -- if no new column was added, validation is not needed
        IF c > 0
        THEN
        
            /* Data validation */
            /* example: */
            SELECT 'ID_DRUG_PROTOCOLS = ' || dp.id_drug_protocols || 'ID_DRUG = ' || dp.id_drug || 'ID_PROTOCOLS = ' ||
                   dp.id_protocols BULK COLLECT
              INTO l_drug_protocols_ids
              FROM drug_protocols dp
             WHERE dp.id_drug IS NULL;
        
            IF l_drug_protocols_ids.exists(1)
               AND l_drug_protocols_ids.count > 0
            THEN
                /* use exception raising to treat each finding: */
                RAISE e_has_findings;
            END IF;
        
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            FOR i IN l_drug_protocols_ids.first .. l_drug_protocols_ids.last
            LOOP
            
                log_error('BAD VALUE: ' || l_drug_protocols_ids(i));
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
