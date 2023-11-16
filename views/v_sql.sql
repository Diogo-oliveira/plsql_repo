
CREATE OR REPLACE VIEW V_SQL AS
SELECT t.table_name,
       (SELECT 'select ' ||
               nvl2(MIN(c.column_name),
                    pk_utils.concat_table(CAST(COLLECT('pk_translation.get_translation(1,t.' || c.column_name || ') ' ||
                                                       lower(REPLACE(c.column_name, 'CODE_', 'desc_')) || ',') AS
                                               table_varchar),
                                          ''),
                    '') || 't.* from ' || t2.table_name || ' t ORDER BY 1;' SQL
          FROM user_tables t2,
               (SELECT *
                  FROM user_tab_columns
                 WHERE column_name LIKE 'CODE\_%' ESCAPE '\'
                   AND data_type = 'VARCHAR2') c
         WHERE t2.table_name = c.table_name(+)
           AND t2.table_name = t.table_name
         GROUP BY t2.table_name) trl_sel,
       'select ''insert into ' || t.table_name || '(' ||
       pk_utils.concat_table(CAST(MULTISET (SELECT c.column_name
                                     FROM user_tab_columns c
                                    WHERE t.table_name = c.table_name
                                    ORDER BY column_id) AS table_varchar),
                             ',') || --
       ') values (' ||
       REPLACE(pk_utils.concat_table(CAST(MULTISET (SELECT '''||' || decode(c.nullable,
                                                                    'Y',
                                                                    ' case when ' || c.column_name ||
                                                                    ' IS NULL THEN ''NULL'' ELSE ') || CASE
                                                       WHEN c.data_type = 'VARCHAR2' THEN
                                                        '''''''''||replace(' || c.column_name || ','''''''','''''''''''')||'''''''''
                                                       WHEN c.data_type = 'DATE' THEN
                                                        '''to_date(''''''||to_char(' || c.column_name ||
                                                        ',''yyyymmdd hh24miss'')||'''''',''''yyyymmdd hh24miss'''')'''
                                                       WHEN c.data_type LIKE 'TIMESTAMP%' THEN
                                                        '''to_timestamp_tz(''''''||to_char(' || c.column_name ||
                                                        ',''yyyymmdd hh24miss TZR'')||'''''',''''yyyymmdd hh24miss TZR'''')'''
                                                       ELSE
                                                        'to_char(' || c.column_name || ')'
                                                   END || decode(c.nullable, 'Y', ' END ') || '||'''
                                             FROM user_tab_columns c
                                            WHERE t.table_name = c.table_name
                                            ORDER BY column_id) AS table_varchar),
                                     ','),
               '''||''',
               '') || ');'' from ' || t.table_name || ' order by 1;' insert_dml_gen,
       'INSERT INTO ' || table_name || '(' ||
       pk_utils.concat_table(CAST(MULTISET (SELECT c.column_name
                                     FROM user_tables t2, user_tab_columns c
                                    WHERE t2.table_name = c.table_name
                                      AND t2.table_name = t.table_name
                                    ORDER BY c.column_id) AS table_varchar),
                             ',') || ') SELECT ' ||
       pk_utils.concat_table(CAST(MULTISET (SELECT 't.' || c.column_name
                                     FROM user_tables t2, user_tab_columns c
                                    WHERE t2.table_name = c.table_name
                                      AND t2.table_name = t.table_name
                                    ORDER BY c.column_id) AS table_varchar),
                             ',') || ' FROM ' || table_name || ' t ' ||
       pk_utils.concat_table(CAST(MULTISET
                                  (SELECT decode(rownum, 1, ' WHERE ') || 'NOT EXISTS(SELECT 0 FROM ' || table_name ||
                                          ' x WHERE ' ||
                                          pk_utils.concat_table(CAST(MULTISET
                                                                     (SELECT decode(o.nullable, 'Y', 'nvl(', '') || 't.' ||
                                                                              c.column_name || decode(o.nullable,
                                                                                                      'Y',
                                                                                                      CASE
                                                                                                          WHEN o.data_type LIKE 'VARCHAR%' THEN
                                                                                                           ',''@'''
                                                                                                          ELSE
                                                                                                           ',0'
                                                                                                      END || ')',
                                                                                                      '') || ' = ' ||
                                                                              decode(o.nullable, 'Y', 'nvl(', '') || 'x.' ||
                                                                              c.column_name || decode(o.nullable,
                                                                                                      'Y',
                                                                                                      CASE
                                                                                                          WHEN o.data_type LIKE 'VARCHAR%' THEN
                                                                                                           ',''@'''
                                                                                                          ELSE
                                                                                                           ',0'
                                                                                                      END || ')',
                                                                                                      '')
                                                                        FROM user_ind_columns c, user_tab_columns o
                                                                       WHERE i.index_name = c.index_name
                                                                         AND i.table_name = c.table_name
                                                                         AND o.table_name = c.table_name
                                                                         AND o.column_name = c.column_name
                                                                       ORDER BY o.column_id) AS table_varchar),
                                                                ' AND ') || ')'
                                     FROM user_indexes i
                                    WHERE i.table_name = t.table_name
                                      AND i.uniqueness = 'UNIQUE') AS table_varchar),
                             ' AND ') || ';' insert_dml_sel,
       'select ''insert_' || lower(regexp_replace(t.table_name, '(\w)[^\W_]*(_|$)', '\1')) || '(' ||
       REPLACE(pk_utils.concat_table(CAST(MULTISET
                                          (SELECT c.column_name || ' => ''||' ||
                                                   decode(c.nullable,
                                                          'Y',
                                                          ' case when ' || c.column_name || ' IS NULL THEN ''NULL'' ELSE ') || CASE
                                                       WHEN c.data_type = 'VARCHAR2' THEN
                                                        '''''''''||' || c.column_name || '||'''''''''
                                                       WHEN c.data_type = 'DATE' THEN
                                                        '''to_date(''''''||to_char(' || c.column_name ||
                                                        ',''yyyymmdd hh24miss'')||'''''',''''yyyymmdd hh24miss'''')'''
                                                       WHEN c.data_type LIKE 'TIMESTAMP%' THEN
                                                        '''to_timestamp_tz(''''''||to_char(' || c.column_name ||
                                                        ',''yyyymmdd hh24miss TZR'')||'''''',''''yyyymmdd hh24miss TZR'''')'''
                                                       ELSE
                                                        'to_char(' || c.column_name || ')'
                                                   END || decode(c.nullable, 'Y', ' END ') || '||'''
                                             FROM user_tab_columns c
                                            WHERE t.table_name = c.table_name
                                            ORDER BY column_id) AS table_varchar),
                                     ','),
               '''||''',
               '') || ');'' from ' || t.table_name || ' order by 1;' insert_procedure
  FROM user_tables t;
