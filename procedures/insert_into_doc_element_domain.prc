CREATE OR REPLACE PROCEDURE insert_into_doc_element_domain
(
    i_lang          LANGUAGE.id_language%TYPE,
    i_code_domain   doc_element_domain.code_element_domain%TYPE,
    i_desc_val      doc_element_domain.desc_val%TYPE,
    i_val           doc_element_domain.val%TYPE,
    i_rank          doc_element_domain.rank%TYPE DEFAULT NULL,
    i_img_name      doc_element_domain.img_name%TYPE DEFAULT NULL,
    i_flg_available doc_element_domain.flg_available%TYPE DEFAULT NULL
) IS
BEGIN

    MERGE INTO doc_element_domain t
    USING (SELECT i_lang          id_language,
                  i_code_domain   code_element_domain,
                  i_desc_val      desc_val,
                  i_val           val,
                  i_rank          rank,
                  i_img_name      img_name,
                  i_flg_available flg_available
             FROM dual) args
    ON (t.id_language = args.id_language AND t.code_element_domain = args.code_element_domain AND t.val = args.val)
    WHEN MATCHED THEN
        UPDATE
           SET t.desc_val      = args.desc_val,
               t.rank          = nvl(args.rank, t.rank),
               t.img_name      = nvl(args.img_name, t.img_name),
               t.flg_available = nvl(args.flg_available, t.flg_available)
    WHEN NOT MATCHED THEN
        INSERT
            (code_element_domain, id_language, desc_val, val, rank, img_name, flg_available)
        VALUES
            (args.code_element_domain,
             args.id_language,
             args.desc_val,
             args.val,
             coalesce(args.rank,
                      (SELECT rank
                         FROM (SELECT rank
                                 FROM doc_element_domain
                                WHERE code_element_domain = i_code_domain
                                  AND val = i_val
                                ORDER BY id_language)
                        WHERE rownum < 2),
                      0),
             nvl(args.img_name,
                 (SELECT img_name
                    FROM (SELECT img_name
                            FROM doc_element_domain
                           WHERE code_element_domain = i_code_domain
                             AND val = i_val
                           ORDER BY id_language)
                   WHERE rownum < 2)),
             nvl(args.flg_available, 'Y'));
END;
/
