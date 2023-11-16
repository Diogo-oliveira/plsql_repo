-- =CONCATENATE("insert_into_soft_lang(6,";A2;",'";C2;"');")

CREATE OR REPLACE PROCEDURE insert_into_soft_lang
(
    i_lang          LANGUAGE.id_language%TYPE,
    i_software      software.id_software%TYPE,
    i_desc_software soft_lang.desc_software%TYPE,
    i_icon          soft_lang.icon%TYPE DEFAULT NULL
) IS
    l_max soft_lang.id_soft_lang%TYPE;
BEGIN

    SELECT MAX(id_soft_lang) + 1
      INTO l_max
      FROM soft_lang;
    --pk_utils.reset_sequence('seq_soft_lang', l_max);

    MERGE INTO soft_lang t
    USING (SELECT a.id_language, --
                  a.id_software,
                  a.desc_software,
                  nvl(b.icon, a.icon) icon
             FROM (SELECT i_lang          id_language, --
                          i_software      id_software,
                          i_desc_software desc_software,
                          i_icon          icon
                     FROM dual) a,
                  soft_lang b
            WHERE b.id_software(+) = a.id_software
              AND b.id_language(+) = 1) args
    ON (t.id_language = args.id_language AND t.id_software = args.id_software)
    WHEN MATCHED THEN
        UPDATE
           SET t.desc_software = args.desc_software, t.icon = args.icon
    WHEN NOT MATCHED THEN
        INSERT
            (id_soft_lang, id_software, id_language, desc_software, icon)
        VALUES
            (l_max, args.id_software, args.id_language, args.desc_software, args.icon);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('ADDING ' || i_software || ': ' || i_desc_software || ' / ' || SQLERRM);
END;
/
