CREATE OR REPLACE FUNCTION update_medication_layer
(
    i_reload_type   IN NUMBER,
    i_reload_backup IN NUMBER DEFAULT 0,
    i_flg_execute   IN NUMBER DEFAULT 0
) RETURN BOOLEAN IS
    RESULT BOOLEAN;

    -- Type of reload 
    reload_int NUMBER := 0;
    reload_ext NUMBER := 1;

    -- Backup of reload
    reload_with_backup NUMBER := 0;
    reload_no_backup   NUMBER := 1;

    -- Flag
    flg_only_output NUMBER := 0;
    flg_execute     NUMBER := 1;

    -- Dynamic strings to be executed
    table_names_ext table_varchar := table_varchar('med',
                                                   'med_route',
                                                   'pharm_group',
                                                   'med_pharm_group',
                                                   'med_subst',
                                                   'med_atc',
                                                   'med_regulation',
																									 'pharm_route',
																									 'pharm_regulation',
                                                   'manip_group',
                                                   'ingred',
                                                   'manip',
                                                   'manip_ingred',
                                                   'dietary');

    table_names_int table_varchar := table_varchar('med_int',
                                                   'pharm_group_int',
                                                   'med_pharm_group_int',
                                                   'med_regulation_int',
                                                   'justification_int',
                                                   'route_int');

    table_version table_varchar := table_varchar('PT', 'USA');

    g_error       VARCHAR2(1000);
    l_statement   VARCHAR2(1000);
    g_format_date VARCHAR2(100) := 'YYYYMMDDHH24MI';
    g_separator   VARCHAR2(100) := '###################################################################################';

BEGIN

    IF (i_reload_type = reload_ext)
    THEN
        dbms_output.put_line(g_separator);
        g_error := '-- Reload external';
        dbms_output.put_line(g_error);
        FOR i IN table_names_ext.FIRST .. table_names_ext.LAST
        LOOP
            dbms_output.put_line(g_separator);
            IF (i_reload_backup = reload_with_backup)
            THEN
                g_error := '-- Backup table ' || table_names_ext(i);
                dbms_output.put_line(g_error);
            
                l_statement := 'create ' || table_names_ext(i) || '_' || to_char(SYSDATE, g_format_date) ||
                               ' as select * from ' || table_names_ext(i);
                dbms_output.put_line(l_statement);
                IF (i_flg_execute = flg_execute)
                THEN
                    EXECUTE IMMEDIATE l_statement;
                END IF;
            END IF;
        
            FOR j IN table_version.FIRST .. table_version.LAST
            LOOP
            
                g_error := '-- Delete table ' || table_names_ext(i) || ' from version ' || table_version(j);
                dbms_output.put_line(g_error);
                l_statement := 'delete from ' || table_names_ext(i) || ' where version = ''' || table_version(j) ||
                               ''' ';
                dbms_output.put_line(l_statement);
                IF (i_flg_execute = flg_execute)
                THEN
                    EXECUTE IMMEDIATE l_statement;
                END IF;
            
                g_error := '-- Insert into table table ' || table_names_ext(i) || ' from version ' || table_version(j);
                dbms_output.put_line(g_error);
                l_statement := 'insert into ' || table_names_ext(i) || ' select * from ' || table_names_ext(i) || '_' ||
                               table_version(j);
                dbms_output.put_line(l_statement);
                IF (i_flg_execute = flg_execute)
                THEN
                    EXECUTE IMMEDIATE l_statement;
                END IF;
            
            END LOOP;
        
            g_error := '-- Compute statistics for ' || table_names_ext(i);
            dbms_output.put_line(g_error);
            l_statement := 'analyze table ' || table_names_ext(i) || ' compute statistics';
            dbms_output.put_line(l_statement);
            IF (i_flg_execute = flg_execute)
            THEN
                EXECUTE IMMEDIATE l_statement;
            END IF;
        
            g_error := '-- Compute statistics for indexes of ' || table_names_ext(i);
            dbms_output.put_line(g_error);
            l_statement := 'analyze table ' || table_names_ext(i) || ' compute statistics for all indexed columns';
            dbms_output.put_line(l_statement);
            IF (i_flg_execute = flg_execute)
            THEN
                EXECUTE IMMEDIATE l_statement;
            END IF;
        
        END LOOP;
    ELSIF (i_reload_type = reload_int)
    THEN
        dbms_output.put_line(g_separator);
        g_error := '-- Reload internal';
        dbms_output.put_line(g_error);
        FOR i IN table_names_int.FIRST .. table_names_int.LAST
        LOOP
        
            dbms_output.put_line(g_separator);
            IF (i_reload_backup = reload_with_backup)
            THEN
                g_error := '-- Backup table ' || table_names_int(i);
                dbms_output.put_line(g_error);
                l_statement := 'create ' || table_names_int(i) || '_' || to_char(SYSDATE, g_format_date) ||
                               ' as select * from ' || table_names_int(i);
                dbms_output.put_line(l_statement);
                IF (i_flg_execute = flg_execute)
                THEN
                    EXECUTE IMMEDIATE l_statement;
                END IF;
            END IF;
        
            FOR j IN table_version.FIRST .. table_version.LAST
            LOOP
            
                g_error := '-- Delete table ' || table_names_int(i) || ' from version ' || table_version(j);
            
                dbms_output.put_line(g_error);
                l_statement := 'delete from ' || table_names_int(i) || ' where version = ''' || table_version(j) ||
                               ''' ';
                dbms_output.put_line(l_statement);
                IF (i_flg_execute = flg_execute)
                THEN
                    EXECUTE IMMEDIATE l_statement;
                END IF;
                g_error := '-- Insert into table table ' || table_names_int(i) || ' from version ' || table_version(j);
            
                dbms_output.put_line(g_error);
                l_statement := 'insert into ' || table_names_int(i) || ' select * from ' || table_names_int(i) || '_' ||
                               table_version(j);
                dbms_output.put_line(l_statement);
                IF (i_flg_execute = flg_execute)
                THEN
                    EXECUTE IMMEDIATE l_statement;
                END IF;
            
            END LOOP;
        
            g_error := '-- Compute statistics for ' || table_names_int(i);
            dbms_output.put_line(g_error);
            l_statement := 'analyze table ' || table_names_int(i) || ' compute statistics';
            dbms_output.put_line(l_statement);
            IF (i_flg_execute = flg_execute)
            THEN
                EXECUTE IMMEDIATE l_statement;
            END IF;
        
            g_error := '-- Compute statistics for indexes of ' || table_names_int(i);
            dbms_output.put_line(g_error);
            l_statement := 'analyze table ' || table_names_int(i) || ' compute statistics for all indexed columns';
            dbms_output.put_line(l_statement);
            IF (i_flg_execute = flg_execute)
            THEN
                EXECUTE IMMEDIATE l_statement;
            END IF;
        
        END LOOP;
    
    END IF;

    COMMIT;

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
    
        g_error := 'UPDATE_MEDICATION_LAYER / ' || g_error || ' / ' || SQLERRM;
        dbms_output.put_line(g_error);
        ROLLBACK;
        RETURN FALSE;
    
END update_medication_layer;
/
