DECLARE
    g_error           t_error_out;
    g_process         BOOLEAN := FALSE;
    g_data_to_migrate NUMBER;
    g_mess            VARCHAR2(4000);
    g_exception EXCEPTION;
    v_id_supply supply.id_supply%TYPE;

    PROCEDURE announce_error(i_message VARCHAR2) IS
    BEGIN
        g_mess := current_timestamp || ': E R R O R : ' || i_message || chr(13) || ' :SQLCODE: ' || SQLCODE ||
                  ' :SQLERRM: ' || SQLERRM || chr(13) || ' :ERROR_STACK: ' || dbms_utility.format_error_stack ||
                  ' :ERROR_BACKTRACE: ' || dbms_utility.format_error_backtrace || ' :CALL_STACK: ' ||
                  dbms_utility.format_call_stack;
        dbms_output.put_line(g_mess);
    
        pk_alertlog.log_error(text => g_mess, object_name => 'MIGRATION_SR_PROTOCOLS');
        dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION_SR_SR_PROTOCOLS'' section. Example:
		select *
			from alertlog.tlog
		 where lsection = ''MIGRATION_SR_PROTOCOLS''
		 order by 2 desc, 3 desc, 1 desc;');
    END announce_error;

    PROCEDURE log_reg(i_message VARCHAR2) IS
        l_m VARCHAR2(4000);
    BEGIN
        l_m := current_timestamp || ': L O G : ' || i_message;
        dbms_output.put_line(l_m);
        pk_alertlog.log_debug(text => l_m, object_name => 'MIGRATION_SR_PROTOCOLS');
    END log_reg;

    FUNCTION validate_content RETURN BOOLEAN IS
        l_count_equip_without_content NUMBER := 0;
        l_count_equip_supply          NUMBER := 0;
    BEGIN
    
        g_mess := 'check if all content have id_content and id_content_new';
        SELECT COUNT(*)
          INTO l_count_equip_without_content
          FROM sr_equip sre
         INNER JOIN equip_protocols ep ON ep.id_sr_equip = sre.id_sr_equip
         WHERE (sre.id_content IS NULL OR sre.id_content_new IS NULL)
           AND sre.flg_hemo_yn = 'N';
    
        IF l_count_equip_without_content = 0
        THEN
        
            g_mess := 'check if all equip exists in supply table';
            SELECT COUNT(*)
              INTO l_count_equip_supply
              FROM sr_equip sre
             INNER JOIN equip_protocols ep ON ep.id_sr_equip = sre.id_sr_equip
              LEFT JOIN supply s ON s.id_content = sre.id_content_new
             WHERE s.id_supply IS NULL
               AND sre.flg_hemo_yn = 'N';
        
            IF l_count_equip_supply = 0
            THEN
                RETURN TRUE;
            ELSE
                g_mess := 'missing sr_equip vs supply';
                RETURN FALSE;
            END IF;
        
        ELSE
            g_mess := 'missing sr_equip id_content or id_content_new';
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
        
    END validate_content;

    FUNCTION check_data_to_migrate(o_data_to_migrate OUT NUMBER) RETURN BOOLEAN IS
    BEGIN
    
        SELECT COUNT(*)
          INTO o_data_to_migrate
          FROM equip_protocols ep
         INNER JOIN sr_equip sre ON ep.id_sr_equip = sre.id_sr_equip
         WHERE sre.flg_hemo_yn = 'N';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            announce_error(g_mess);
            RETURN FALSE;
    END check_data_to_migrate;

BEGIN

    log_reg('Start migration from equip_protocols to sr_supply_protocols...');

    g_mess := 'Check if there is data to migrate';
    IF NOT check_data_to_migrate(g_data_to_migrate)
    THEN
        RAISE g_exception;
    END IF;

    IF g_data_to_migrate > 0
    THEN
        IF validate_content
        THEN
            g_process := TRUE;
        ELSE
            g_process := FALSE;
            g_mess    := 'Validate content:' || g_mess;
            RAISE g_exception;
        END IF;
    
        IF g_process
        THEN
        
            FOR rec IN (SELECT *
                          FROM equip_protocols
                         WHERE id_sr_equip IN (SELECT s.id_sr_equip
                                                 FROM sr_equip s
                                                WHERE s.flg_hemo_yn = 'N')
                         ORDER BY 1)
            LOOP
            
                log_reg('ID_EQUIP_PROTOCOLS:' || rec.id_equip_protocols || ' ID_PROTOCOLS:' || rec.id_protocols ||
                        ' id_sr_equip:' || rec.id_sr_equip);
            
                g_mess := 'get id_supply';
                SELECT s.id_supply
                  INTO v_id_supply
                  FROM supply s
                 INNER JOIN sr_equip sre ON s.id_content = sre.id_content_new
                 WHERE sre.id_sr_equip = rec.id_sr_equip;
            
                g_mess := 'insert sr_supply_protocols: id_protocols=' || rec.id_protocols || ' id_supply=' ||
                          v_id_supply || ' qty_req=' || rec.qty_req || ' flg_available=' || rec.flg_available ||
                          ' rank=' || rec.rank;
                log_reg(g_mess);
                BEGIN
                    INSERT INTO sr_supply_protocols
                        (id_protocols, id_supply, qty_req, flg_available, rank)
                    VALUES
                        (rec.id_protocols, v_id_supply, rec.qty_req, rec.flg_available, rec.rank);
                EXCEPTION
                    WHEN dup_val_on_index THEN
                        log_reg('...Already inserted.');
                END;
            
            END LOOP;
        
        ELSE
            announce_error(g_mess);
        END IF;
    
    ELSE
        log_reg(' there is no data to migrate :) ... ');
    END IF;

    log_reg(' ...end migration FROM equip_protocols to sr_supply_protocols. ');

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        announce_error(g_mess);
        ROLLBACK;
END;
