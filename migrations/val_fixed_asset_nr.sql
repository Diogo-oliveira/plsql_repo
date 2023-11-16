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
        l_aux_count_barcode pls_integer;
				l_aux_count_fixed pls_integer;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        /* example: */
        SELECT count(*)
				  into l_aux_count_barcode
          FROM supply_barcode sb
         WHERE sb.asset_number is not null;
				 
				 SELECT count(*)
				  into l_aux_count_fixed
          FROM supply_fixed_asset_nr sb         ;
    
        IF l_aux_count_barcode <> l_aux_count_fixed
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
                log_error('BAD VALUE: Nr of fixed asset nrs in the supply_barcode table: ' || l_aux_count_barcode || '. Nr of fixed asset nrs in the new table (supply_fixed_asset_nr): ' || l_aux_count_fixed);
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
