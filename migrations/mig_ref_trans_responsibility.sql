DECLARE
    l_count PLS_INTEGER;
    l_aux   PLS_INTEGER;
BEGIN
    -- 1- inactivar indices que existam sobre a coluna ID_PROF_CREATED    
    EXECUTE IMMEDIATE 'ALTER INDEX RTR_INN_ORIG_FK_IDX UNUSABLE';

    -- 2- activar o paralelismo e obter valores    
    -- 2a- activar paralelismo
    EXECUTE IMMEDIATE 'alter session enable parallel dml';

    -- 2b- obter valor original da tabela
    BEGIN
        SELECT degree
          INTO l_aux
          FROM user_tables
         WHERE table_name = 'REF_TRANS_RESPONSIBILITY';
    EXCEPTION
        WHEN no_data_found THEN
            l_aux := 1;
    END;

    -- 2n- obter o n de cpus para paralelizar
    SELECT VALUE
      INTO l_count
      FROM v$parameter
     WHERE name = 'cpu_count';

    -- 3- alterar a tabela
    EXECUTE IMMEDIATE 'ALTER TABLE REF_TRANS_RESPONSIBILITY PARALLEL (DEGREE ' || l_count || ')';

    -- 4- fazer script de migracao
    UPDATE (SELECT rtr.id_inst_orig_tr rtr_id_inst_orig, p.id_inst_orig p_id_inst_orig
              FROM ref_trans_responsibility rtr
              JOIN p1_external_request p
                ON p.id_external_request = rtr.id_external_request
             WHERE rtr.id_workflow = 10
               AND rtr.id_inst_orig_tr IS NULL)
       SET rtr_id_inst_orig = p_id_inst_orig;

    -- 5- repor valor original
    EXECUTE IMMEDIATE 'ALTER TABLE REF_TRANS_RESPONSIBILITY PARALLEL (DEGREE ' || l_aux || ')';

    -- 6- voltar a activar os indices que existam sobre a coluna ID_PROF_CREATED
    EXECUTE IMMEDIATE 'ALTER INDEX RTR_INN_ORIG_FK_IDX REBUILD';
END;
/
