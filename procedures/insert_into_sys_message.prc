--=CONCATENATE("insert_into_sys_message(0,'";C2;"','";SUBSTITUTE(E2;"'";"''");"',";A2;",";B2;",'','A');")
CREATE OR REPLACE PROCEDURE insert_into_sys_message
(
    i_lang           LANGUAGE.id_language%TYPE,
    i_code_message   sys_message.code_message%TYPE,
    i_desc_message   sys_message.desc_message%TYPE,
    i_flg_type       sys_message.flg_type%TYPE DEFAULT NULL,
    i_software       software.id_software%TYPE DEFAULT 0,
    i_institution    institution.id_institution%TYPE DEFAULT 0,
    i_img_name       sys_message.img_name%TYPE DEFAULT NULL,
    i_id_sys_message sys_message.id_sys_message%TYPE DEFAULT NULL,
    i_module         sys_message.module%TYPE DEFAULT NULL
) IS
BEGIN
    MERGE INTO sys_message t
    USING (SELECT i_code_message code_message, --
                  i_desc_message desc_message, --
                  i_flg_type flg_type,
                  i_lang id_language,
                  'Y' flg_available,
                  i_img_name img_name,
                  i_software id_software,
                  i_institution id_institution,
                  i_module      module
             FROM dual) args
    ON (t.id_language = args.id_language AND t.code_message = args.code_message --
    AND t.id_institution = args.id_institution AND t.id_software = args.id_software)
    WHEN MATCHED THEN
        UPDATE
           SET t.desc_message = args.desc_message,
               t.img_name     = nvl(args.img_name, t.img_name),
               t.flg_type     = nvl(args.flg_type, t.flg_type),
               t.module       = nvl(args.module  , t.module  )
    WHEN NOT MATCHED THEN
        INSERT
            (code_message,
             desc_message,
             flg_type,
             id_language,
             flg_available,
             img_name,
             id_sys_message,
             id_software,
             id_institution,
             module,
             adw_last_update)
        VALUES
            (args.code_message,
             args.desc_message,
             coalesce(args.flg_type,
                      (SELECT flg_type
                         FROM (SELECT s.flg_type
                                 FROM sys_message s
                                WHERE s.flg_type IS NOT NULL
                                  AND s.code_message = i_code_message
                                  AND s.id_software = i_software
                                  AND s.id_institution = i_institution
                                ORDER BY s.id_language ASC)
                        WHERE rownum < 2),
                      'A'),
             args.id_language,
             args.flg_available,
             nvl(args.img_name,
                 (SELECT img_name
                    FROM (SELECT s.img_name
                            FROM sys_message s
                           WHERE s.img_name IS NOT NULL
                             AND s.code_message = i_code_message
                             AND s.id_software = i_software
                             AND s.id_institution = i_institution
                           ORDER BY s.id_language ASC)
                   WHERE rownum < 2)),
             --se i_id_sys_message não é fornecido tem-se que colocar algo
             nvl(i_id_sys_message, seq_sys_message.NEXTVAL),
             args.id_software,
             args.id_institution,
             args.module,
             SYSDATE);
END;
/
