CREATE OR REPLACE FORCE VIEW v_translation AS
SELECT 'pk_translation.insert_into_translation(' || id_language || ',''' ||
       REPLACE(REPLACE(code_translation, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''',''' ||
       REPLACE(REPLACE(descr, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''');' query_insert,
       'UPDATE translation SET desc_translation_' || id_language || ' = ''' ||
       REPLACE(REPLACE(descr, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') || ''' where code_translation = ''' ||
       REPLACE(REPLACE(code_translation, '''', ''''''), chr(10) || '@', chr(10) || '''||''@') ||
       ''' AND id_language = ' || id_language || ';' query_update,
       'SELECT * FROM ' || substr(code_translation, 1, instr(code_translation, '.', 1, 1) - 1) || ' WHERE id_' ||
       lower(substr(code_translation, 1, instr(code_translation, '.', 1, 1) - 1)) || ' = ' ||
       lower(substr(code_translation, instr(code_translation, '.', 1, 2) + 1)) || ';' query_select_main_table,
       NULL id_main_table,
       '<row><table_name>TRANSLATION</table_name>' || '<id_language>' || id_language || '</id_language>' ||
        '<code_translation>' || code_translation || '</code_translation>' || '<column_name>desc_translation_' ||
        id_language || '</column_name>' || '<to_translate>' ||
        REPLACE(REPLACE(REPLACE(CASE
                                    WHEN code_translation LIKE 'SYS\_BUTTON.CODE\_BUTTON.%' ESCAPE '\' THEN
                                     regexp_replace(descr, '([[:alnum:]])-[[:blank:]]*([[:alnum:]])', '\1\2')
                                    ELSE
                                     descr
                                END,
                                '&',
                                '&' || 'amp;'),
                        '>',
                        '&' || 'gt;'),
                '<',
                '&' || 'lt;') || '</to_translate></row>' trados_xml,
       NULL id_translation,
       t.id_language,
       t.code_translation,
       descr desc_translation
  FROM (SELECT 1 id_language, t1.code_translation, t1.desc_lang_1 descr
          FROM translation t1
        UNION ALL
        SELECT 2 id_language, t1.code_translation, t1.desc_lang_2 descr
          FROM translation t1
        UNION ALL
        SELECT 3 id_language, t1.code_translation, t1.desc_lang_3 descr
          FROM translation t1
        UNION ALL
        SELECT 4 id_language, t1.code_translation, t1.desc_lang_4 descr
          FROM translation t1
        UNION ALL
        SELECT 5 id_language, t1.code_translation, t1.desc_lang_5 descr
          FROM translation t1
        UNION ALL
        SELECT 6 id_language, t1.code_translation, t1.desc_lang_6 descr
          FROM translation t1
        UNION ALL
        SELECT 7 id_language, t1.code_translation, t1.desc_lang_7 descr
          FROM translation t1
        UNION ALL
        SELECT 8 id_language, t1.code_translation, t1.desc_lang_8 descr
          FROM translation t1
        UNION ALL
        SELECT 9 id_language, t1.code_translation, t1.desc_lang_9 descr
          FROM translation t1
        UNION ALL
        SELECT 10 id_language, t1.code_translation, t1.desc_lang_10 descr
          FROM translation t1
        UNION ALL
        SELECT 11 id_language, t1.code_translation, t1.desc_lang_11 descr
          FROM translation t1
        UNION ALL
        SELECT 12 id_language, t1.code_translation, t1.desc_lang_12 descr
          FROM translation t1
        UNION ALL
        SELECT 13 id_language, t1.code_translation, t1.desc_lang_13 descr
          FROM translation t1
        UNION ALL
        SELECT 14 id_language, t1.code_translation, t1.desc_lang_14 descr
          FROM translation t1
        UNION ALL
        SELECT 15 id_language, t1.code_translation, t1.desc_lang_15 descr
          FROM translation t1
        UNION ALL
        SELECT 16 id_language, t1.code_translation, t1.desc_lang_16 descr
          FROM translation t1
        UNION ALL
        SELECT 17 id_language, t1.code_translation, t1.desc_lang_17 descr
          FROM translation t1
        UNION ALL
        SELECT 18 id_language, t1.code_translation, t1.desc_lang_18 descr
          FROM translation t1
        UNION ALL
        SELECT 19 id_language, t1.code_translation, t1.desc_lang_19 descr
          FROM translation t1
        UNION ALL
        SELECT 20 id_language, t1.code_translation, t1.desc_lang_20 descr
          FROM translation t1
        UNION ALL
        SELECT 21 id_language, t1.code_translation, t1.desc_lang_21 descr
          FROM translation t1
        UNION ALL
        SELECT 22 id_language, t1.code_translation, t1.desc_lang_22 descr
          FROM translation t1) t;
