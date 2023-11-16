CREATE OR REPLACE PROCEDURE delete_cascade
(
    i_id         IN VARCHAR2,
    i_table_name IN VARCHAR2,
    i_owner      IN VARCHAR2 DEFAULT 'ALERT',
    i_debug      IN BOOLEAN DEFAULT FALSE
) IS

    --vars to store parsed ids, to prevent cycles
    TYPE t_tablepk IS TABLE OF BOOLEAN INDEX BY VARCHAR2(600);
    TYPE t_pks IS TABLE OF t_tablepk INDEX BY VARCHAR2(62);

    l_parsed_rows t_pks;

    --vars to store sql
    TYPE cursor_type IS REF CURSOR;

    TYPE t_row IS RECORD(
        query_select VARCHAR2(4000),
        query_update VARCHAR2(4000),
        query_delete VARCHAR2(4000),
        table_name   VARCHAR2(30),
        owner        VARCHAR(30));
    TYPE t_set IS TABLE OF t_row;

    TYPE t_tbl_sqls IS TABLE OF t_set INDEX BY VARCHAR2(62);

    TYPE t_tbl_sql IS TABLE OF VARCHAR2(800) INDEX BY VARCHAR2(62);

    l_sql_chk t_tbl_sql;
    l_sql_del t_tbl_sql;
    l_sql_get t_tbl_sqls;

    l_count PLS_INTEGER;

    l_sql table_varchar := table_varchar();

    PROCEDURE log(i_msg IN VARCHAR2) IS
    BEGIN
        IF i_debug
        THEN
            dbms_output.put_line(i_msg);
        END IF;
    END;

    PROCEDURE push_sql(i_sql IN VARCHAR2) IS
    BEGIN
        l_sql.EXTEND(1);
        l_sql(l_sql.COUNT) := i_sql;
    END;

    PROCEDURE pop_sql IS
    BEGIN
        IF l_sql.COUNT > 0
        THEN
            l_sql.DELETE(l_sql.COUNT);
        END IF;
    END;

    --return false -> new record
    --return true -> already visited record, do update instead
    FUNCTION delete_cascade_inner
    (
        i_id         IN VARCHAR2,
        i_table_name IN VARCHAR2,
        i_owner      IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_ids table_varchar;
        c_cur cursor_type;
        l_row t_row;
        l_sql VARCHAR2(2000);
    BEGIN
    
        BEGIN
            IF l_parsed_rows(i_owner || '.' || i_table_name) (to_char(i_id))
            THEN
                RETURN TRUE;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                --no_data_found
                NULL;
        END;
    
		if i_table_name IN ('EPISODE','VISIT','PATIENT') THEN
		RETURN FALSE;
		END IF;
		
        l_parsed_rows(i_owner || '.' || i_table_name)(to_char(i_id)) := TRUE;
        --log(I_OWNER||'.'|i_table_name || ' ' || CASE WHEN l_sql_chk.EXISTS(I_OWNER||'.'|i_table_name) THEN 'ok' ELSE 'ko' END);
    
        IF NOT l_sql_chk.EXISTS(i_owner || '.' || i_table_name)
        THEN
            log(i_owner || '.' || i_table_name);
            SELECT 'select count(0) from ' || p.owner || '.' || p.table_name || ' where ' ||
                   (SELECT pk_utils.concat_table(CAST(MULTISET (SELECT pc.column_name
                                                         FROM all_cons_columns pc
                                                        WHERE p.table_name = pc.table_name
                                                          AND p.owner = pc.owner
                                                          AND p.constraint_name = pc.constraint_name
                                                        ORDER BY pc.column_name) AS table_varchar),
                                                 '||''|''||')
                      FROM dual) || ' = :i_val' sel,
                   'delete ' || p.owner || '.' || p.table_name || ' where ' ||
                   (SELECT pk_utils.concat_table(CAST(MULTISET (SELECT pc.column_name
                                                         FROM all_cons_columns pc
                                                        WHERE p.table_name = pc.table_name
                                                          AND p.owner = pc.owner
                                                          AND p.constraint_name = pc.constraint_name
                                                        ORDER BY pc.column_name) AS table_varchar),
                                                 '||''|''||')
                      FROM dual) || ' = :i_val' del
              INTO l_sql_chk(i_owner || '.' || i_table_name), l_sql_del(i_owner || '.' || i_table_name)
              FROM all_constraints p
             WHERE p.table_name = i_table_name
               AND p.owner = i_owner
               AND p.constraint_type = 'P';
        
            SELECT DISTINCT (SELECT 'select ' ||
                                    pk_utils.concat_table(CAST(MULTISET (SELECT rc2.column_name
                                                                  FROM all_constraints r2, all_cons_columns rc2
                                                                 WHERE r2.constraint_type = 'P'
                                                                   AND r2.table_name = r.table_name
                                                                   AND r2.owner = r.owner
                                                                   AND rc2.table_name = r2.table_name
                                                                   AND rc2.owner = r2.owner
                                                                   AND rc2.constraint_name = r2.constraint_name
                                                                 ORDER BY rc2.column_name) AS table_varchar),
                                                          '||''|''||') || ' id from ' || r.owner || '.' || r.table_name ||
                                    ' where ' || rc.column_name || ' = :i_val order by 1 desc'
                               FROM dual
                              WHERE EXISTS (SELECT rc2.column_name
                                       FROM all_constraints r2, all_cons_columns rc2
                                      WHERE r2.constraint_type = 'P'
                                        AND r2.table_name = r.table_name
                                        AND r2.owner = r.owner
                                        AND rc2.table_name = r2.table_name
                                        AND rc2.owner = r2.owner
                                        AND rc2.constraint_name = r2.constraint_name)) sel,
                            (SELECT 'update ' || r.owner || '.' || r.table_name || ' set ' || rc.column_name ||
                                    ' = NULL where ' || rc.column_name || ' = :i_val'
                               FROM dual
                              WHERE EXISTS (SELECT rc2.column_name
                                       FROM all_constraints r2, all_cons_columns rc2
                                      WHERE r2.constraint_type = 'P'
                                        AND r2.table_name = r.table_name
                                        AND r2.owner = r.owner
                                        AND rc2.table_name = r2.table_name
                                        AND rc2.owner = r2.owner
                                        AND rc2.constraint_name = r2.constraint_name)) updt,
                            'delete from ' || r.owner || '.' || r.table_name || ' where ' || rc.column_name ||
                            ' = :i_val' delete_direct,
                            r.table_name,
                            r.owner BULK COLLECT
              INTO l_sql_get(i_owner || '.' || i_table_name)
              FROM all_constraints p, all_constraints r, all_cons_columns rc
             WHERE p.table_name = i_table_name
               AND p.owner = i_owner
               AND p.constraint_type = 'P'
                  --
               AND r.r_constraint_name = p.constraint_name
               AND r.r_owner = p.owner
               AND r.constraint_type = 'R'
               AND r.table_name = rc.table_name
               AND r.constraint_name = rc.constraint_name;
        
            --log(l_sql_chk(i_table_name));
            --log(l_sql_del(i_table_name));
            --
        END IF;
    
        l_sql := REPLACE(l_sql_chk(i_owner || '.' || i_table_name), ':i_val', i_id) || ';';
        log(l_sql);
        push_sql(l_sql);
        EXECUTE IMMEDIATE l_sql_chk(i_owner || '.' || i_table_name)
            INTO l_count
            USING i_id;
        --  dbms_output.put_line(l_count);
        IF l_count > 0
        THEN
        
            FOR k IN 1 .. l_sql_get(i_owner || '.' || i_table_name).COUNT
            LOOP
                l_row := l_sql_get(i_owner || '.' || i_table_name) (k);
            
                IF l_row.query_select IS NOT NULL
                THEN
                    l_sql := REPLACE(l_row.query_select, ':i_val', i_id) || ';';
                    log(l_sql);
                    push_sql(l_sql);
                    ---
                    OPEN c_cur FOR l_row.query_select
                        USING i_id;
                    FETCH c_cur BULK COLLECT
                        INTO l_ids;
                    CLOSE c_cur;
                
                    FOR i IN 1 .. l_ids.COUNT
                    LOOP
                        IF delete_cascade_inner(l_ids(i), l_row.table_name, l_row.owner)
                        THEN
                            --run update to remove fk reference
                            l_sql := REPLACE(l_row.query_update, ':i_val', i_id) || ';';
                            log(l_sql);
                            push_sql(l_sql);
                            EXECUTE IMMEDIATE l_row.query_update
                                USING i_id;
                            pop_sql();
                        END IF;
                    END LOOP;
                    ---
                    pop_sql(); --query_select
                ELSE
                    l_sql := REPLACE(l_row.query_delete, ':i_val', i_id) || ';';
                    log(l_sql);
                    push_sql(l_sql);
                    EXECUTE IMMEDIATE l_row.query_delete
                        USING i_id;
                    pop_sql();
                END IF;
            
            END LOOP;
        
            l_sql := REPLACE(l_sql_del(i_owner || '.' || i_table_name), ':i_val', i_id) || ';';
            log(l_sql);
            push_sql(l_sql);
            EXECUTE IMMEDIATE l_sql_del(i_owner || '.' || i_table_name)
                USING i_id;
            pop_sql();
        
        END IF;
        pop_sql();
    
        RETURN FALSE;
        --EXCEPTION
        ---    WHEN OTHERS THEN
        --       dbms_output.put_line(i_table_name || ' / ' || SQLERRM);
        --       RAISE;
    END;
BEGIN
    IF delete_cascade_inner(i_id, i_table_name, i_owner)
    THEN
        NULL;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF l_sql.COUNT > 0
        THEN
            FOR i IN 1 .. l_sql.COUNT
            LOOP
                BEGIN
                    dbms_output.put_line(l_sql(l_sql.COUNT - i + 1));
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END LOOP;
        END IF;
        RAISE;
END;
/
