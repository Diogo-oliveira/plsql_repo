CREATE OR REPLACE PROCEDURE insert_into_functionality_help
(
    i_lang                  LANGUAGE.id_language%TYPE,
    i_code_help             functionality_help.code_help%TYPE,
    i_desc_help             functionality_help.desc_help%TYPE,
    i_software              software.id_software%TYPE DEFAULT 0,
    i_id_functionality_help functionality_help.id_functionality_help%TYPE DEFAULT NULL,
    i_module                functionality_help.module%TYPE DEFAULT NULL
) IS
BEGIN
    MERGE INTO functionality_help t
    USING (SELECT i_code_help code_help, --
                  i_desc_help desc_help, --
                  i_lang id_language,
                  'Y' flg_available,
                  i_software id_software,
                  i_module module
             FROM dual) args
    ON (t.id_language = args.id_language AND t.code_help = args.code_help --
    AND t.id_software = args.id_software)
    WHEN MATCHED THEN
        UPDATE
           SET t.desc_help = args.desc_help, t.module = nvl(args.module, t.module)
    WHEN NOT MATCHED THEN
        INSERT
            (id_functionality_help, code_help, desc_help, id_language, flg_available, id_software, module)
        VALUES
            ( --se i_id_sys_message não é fornecido tem-se que colocar algo
             nvl(i_id_functionality_help, seq_functionality_help.NEXTVAL),
             args.code_help,
             args.desc_help,
             args.id_language,
             args.flg_available,
             args.id_software,
             args.module);
END;
/
