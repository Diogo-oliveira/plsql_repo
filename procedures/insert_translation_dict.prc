CREATE OR REPLACE PROCEDURE insert_translation_dict
(
    i_filter   IN translation.code_translation%TYPE,
    i_lang_src IN LANGUAGE.id_language%TYPE,
    i_desc_src IN translation.desc_translation%TYPE,
    i_lang_dst IN LANGUAGE.id_language%TYPE,
    i_desc_dst IN translation.desc_translation%TYPE,
    i_if_null  IN BOOLEAN DEFAULT FALSE
) IS
    l_filter translation.code_translation%TYPE := REPLACE(REPLACE(i_filter, '\', '\\'), '_', '\_') || '%';
    l_trl    table_varchar;
    l_flag   VARCHAR2(1) := CASE WHEN i_if_null THEN 'Y' ELSE 'N' END;
BEGIN

    IF i_filter IS NULL
    THEN
        RETURN;
    END IF;
    SELECT code_translation BULK COLLECT
      INTO l_trl
      FROM translation a
     WHERE a.code_translation LIKE l_filter ESCAPE '\'
       AND a.id_language = i_lang_src
       AND a.desc_translation = i_desc_src
       AND NOT EXISTS
     (SELECT 0
              FROM translation b
             WHERE b.code_translation = a.code_translation
               AND b.id_language = i_lang_dst
               AND b.desc_translation = i_desc_dst)
       AND (l_flag = 'N' OR NOT EXISTS (SELECT 0
                                          FROM translation b
                                         WHERE b.code_translation = a.code_translation
                                           AND b.id_language = i_lang_dst
                                           AND b.desc_translation IS NOT NULL));

    FOR i IN 1 .. l_trl.COUNT
    LOOP
        dbms_output.put_line('insert_into_translation(' || i_lang_dst || ',''' || l_trl(i) || ''',''' ||
                             REPLACE(i_desc_dst, '''', '''''') || ''');');
        insert_into_translation(i_lang_dst, l_trl(i), i_desc_dst);
    END LOOP;

END;
/
