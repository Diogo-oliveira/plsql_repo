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

    PROCEDURE do_my_validation IS
        /* Declarations */
        e_has_findings EXCEPTION;
        l_sr_reserv_req_ids table_varchar;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT 'ID_SR_RESERV_REQ = ' || srr.id_sr_reserv_req BULK COLLECT
          INTO l_sr_reserv_req_ids
          FROM sr_reserv_req srr
         INNER JOIN sr_equip se ON srr.id_sr_equip = se.id_sr_equip
                               AND se.flg_hemo_yn = 'N'
          LEFT JOIN sr_reserv_req_to_supply rts ON srr.id_sr_reserv_req = rts.id_sr_reserv_req
         WHERE rts.id_sr_reserv_req IS NULL;
    
        IF l_sr_reserv_req_ids.exists(1)
           AND l_sr_reserv_req_ids.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            FOR i IN l_sr_reserv_req_ids.first .. l_sr_reserv_req_ids.last
            LOOP
                log_error('BAD VALUE: ' || l_sr_reserv_req_ids(i));
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
