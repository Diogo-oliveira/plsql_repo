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
        l_equip_protocols_ids table_varchar;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT 'ID_EQUIP_PROTOCOLS = ' || ep.id_equip_protocols BULK COLLECT
          INTO l_equip_protocols_ids
          FROM equip_protocols ep
         INNER JOIN sr_equip se ON se.id_sr_equip = ep.id_sr_equip
                               AND se.flg_hemo_yn = 'N'
         INNER JOIN supply s ON s.id_content = se.id_content_new
          LEFT JOIN sr_supply_protocols ss ON ss.id_protocols = ep.id_protocols
                                          AND ss.id_supply = s.id_supply
         WHERE ss.id_protocols IS NULL;
    
        IF l_equip_protocols_ids.exists(1)
           AND l_equip_protocols_ids.count > 0
        THEN
            /* use exception raising to treat each finding: */
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN e_has_findings THEN
            FOR i IN l_equip_protocols_ids.first .. l_equip_protocols_ids.last
            LOOP
                log_error('BAD VALUE: ' || l_equip_protocols_ids(i));
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
