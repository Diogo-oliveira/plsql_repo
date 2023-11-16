CREATE OR REPLACE PROCEDURE insert_into_sys_domain_mkt
(
    i_lang          LANGUAGE.id_language%TYPE,
    i_code_domain   sys_domain.code_domain%TYPE,
    i_desc_val      sys_domain.desc_val%TYPE,
    i_val           sys_domain.val%TYPE,
    i_rank          sys_domain.rank%TYPE DEFAULT NULL,
    i_img_name      sys_domain.img_name%TYPE DEFAULT NULL,
    i_flg_available sys_domain.flg_available%TYPE DEFAULT NULL
) IS
BEGIN

    MERGE INTO sys_domain_mkt t
    USING (SELECT i_code_domain code_domain, i_val val, i_rank rank_default, 0 id_market, 'A' flg_action
             FROM dual) args
    ON (t.code_domain = args.code_domain AND t.val = args.val AND t.id_market = args.id_market)
    WHEN MATCHED THEN
        UPDATE
           SET t.rank_default = nvl(args.rank_default, t.rank_default)
    WHEN NOT MATCHED THEN
        INSERT
            (id_sys_domain_mkt, code_domain, val, rank_default, id_market, flg_action)
        VALUES
            (seq_sys_domain_mkt.NEXTVAL,
             args.code_domain,
             args.val,
             coalesce(args.rank_default,
                      (SELECT rank_default
                         FROM (SELECT rank_default
                                 FROM sys_domain_mkt
                                WHERE code_domain = i_code_domain
                                  AND val = i_val
                                ORDER BY id_market)
                        WHERE rownum < 2),
                      0),
             args.id_market,
             nvl(args.flg_action, 'A'));

END;
/
