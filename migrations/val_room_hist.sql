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
        l_count_dcs_ids             PLS_INTEGER;
        l_count_dcs_ids_hist        PLS_INTEGER;
        
        TYPE tab_room_hist IS TABLE OF room_hist%ROWTYPE;
    
        l_tab_room_hist     tab_room_hist;
        l_not_migrated_ids_dcs varchar2(32000) := null;
        l_not_migrated_ids_esc varchar2(32000):=null;
    BEGIN
        /* Initializations */
    
        /* Data validation */
        SELECT rh.* BULK COLLECT
          INTO l_tab_room_hist
          FROM room_hist rh;
    
        FOR rec IN 1 .. l_tab_room_hist.count
        LOOP
            l_count_dcs_ids        := 0;
            
            IF (l_tab_room_hist(rec).dcs_ids IS NOT NULL AND l_tab_room_hist(rec).dcs_ids.exists(1))
            THEN
                SELECT COUNT(1)
                  INTO l_count_dcs_ids
                  FROM room_hist rh
                 WHERE rh.id_room_hist = l_tab_room_hist(rec).id_room_hist;
                
                IF (l_count_dcs_ids = 0)
                THEN
                   l_not_migrated_ids_dcs := l_not_migrated_ids_dcs || to_char(l_tab_room_hist(rec).id_room_hist) || ' ';
                END IF;
            END IF;
        
        END LOOP;
    
        IF (l_not_migrated_ids_dcs is not null)
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        WHEN e_has_findings THEN
            log_error('ERROR ON ROOM HIST MIGRATION. NOT migrated dcs_ids: ' || l_not_migrated_ids_dcs);
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
