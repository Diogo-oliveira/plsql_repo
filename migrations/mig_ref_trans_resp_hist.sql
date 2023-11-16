DECLARE
    l_count PLS_INTEGER;
    l_aux   PLS_INTEGER;
BEGIN
    -- 1- activar o paralelismo e obter valores    
    -- 1a- activar paralelismo
    EXECUTE IMMEDIATE 'alter session enable parallel dml';

    -- 1b- obter valor original da tabela
    BEGIN
        SELECT degree
          INTO l_aux
          FROM user_tables
         WHERE table_name = 'REF_TRANS_RESP_HIST';
    EXCEPTION
        WHEN no_data_found THEN
            l_aux := 1;
    END;

    -- 2- obter o n de cpus para paralelizar
    SELECT VALUE
      INTO l_count
      FROM v$parameter
     WHERE name = 'cpu_count';

    -- 3- alterar a tabela
    EXECUTE IMMEDIATE 'ALTER TABLE REF_TRANS_RESP_HIST PARALLEL (DEGREE ' || l_count || ')';

    -- 4- fazer script de migracao
    UPDATE (SELECT rtr.id_inst_orig_tr rtr_id_inst_orig, rtrh.id_inst_orig_tr rtrh_id_inst_orig
              FROM ref_trans_responsibility rtr
              JOIN ref_trans_resp_hist rtrh
                ON rtrh.id_trans_resp = rtr.id_trans_resp
             WHERE rtr.id_workflow = 10
               AND rtrh.id_inst_orig_tr IS NULL)
       SET rtrh_id_inst_orig = rtr_id_inst_orig;

    -- 5- repor valor original
    EXECUTE IMMEDIATE 'ALTER TABLE REF_TRANS_RESP_HIST PARALLEL (DEGREE ' || l_aux || ')';
END;
/
