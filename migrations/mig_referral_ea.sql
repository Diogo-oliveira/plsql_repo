-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 05/11/2013 17:19
-- CHANGE REASON: [ALERT-268787] 
DECLARE
    l_count PLS_INTEGER;
    l_aux   PLS_INTEGER;
BEGIN
    -- 0- fazer backup da tabela
    SELECT COUNT(1)
      INTO l_aux
      FROM user_tables t
     WHERE t.table_name = 'REFERRAL_EA_BCK2';

    IF l_aux = 0
    THEN
        pk_frmw_objects.insert_into_frmw_objects(i_owner => 'ALERT', i_obj_name => 'REFERRAL_EA_BCK2', i_obj_type => 'TABLE', i_flg_category => 'DSV');
EXECUTE IMMEDIATE 'CREATE TABLE referral_ea_bck2 AS SELECT id_external_request, id_prof_orig FROM referral_ea WHERE id_prof_orig IS NOT NULL AND (id_workflow IS NULL OR id_workflow != 4)';
    END IF;

-- 1- activar o paralelismo e obter valores    
    -- 1a- activar paralelismo
    EXECUTE IMMEDIATE 'alter session enable parallel dml';
    -- 1b- obter valor original da tabela
    BEGIN
        SELECT degree
          INTO l_aux
          FROM user_tables
         WHERE table_name = 'REFERRAL_EA';
    EXCEPTION
        WHEN no_data_found THEN
            l_aux := 1;
    END;
    -- 1c- obter o n de cpus para paralelizar
    SELECT VALUE
      INTO l_count
      FROM v$parameter
     WHERE name = 'cpu_count';

    -- 2- alterar a tabela
    EXECUTE IMMEDIATE 'ALTER TABLE REFERRAL_EA PARALLEL (DEGREE ' || l_count || ')';

    -- 3- fazer script de migracao de uma so vez
    -- id_prof_orig so deve estar preenchido quando wf=4 (para ja)
    UPDATE referral_ea r
       SET id_prof_orig = NULL
     WHERE id_prof_orig IS NOT NULL
       AND (id_workflow IS NULL OR id_workflow != 4);

    -- 4- repor valor original
    EXECUTE IMMEDIATE 'ALTER TABLE REFERRAL_EA PARALLEL (DEGREE ' || l_aux || ')';

END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 27/11/2013 10:59
-- CHANGE REASON: [ALERT-267879] 
DECLARE
    l_count PLS_INTEGER;
    l_aux   PLS_INTEGER;
    g_error VARCHAR2(1000 CHAR);

    TYPE t_coll_num_order IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(200 CHAR);
    l_num_order_tab t_coll_num_order;
BEGIN
    -- 0- fazer backup da tabela
    SELECT COUNT(1)
      INTO l_aux
      FROM user_tables t
     WHERE t.table_name = 'REFERRAL_EA_BCK';

    IF l_aux = 0
    THEN
        pk_frmw_objects.insert_into_frmw_objects(i_owner => 'ALERT', i_obj_name => 'REFERRAL_EA_BCK', i_obj_type => 'TABLE', i_flg_category => 'DSV');
EXECUTE IMMEDIATE 'CREATE TABLE referral_ea_bck AS SELECT * FROM referral_ea WHERE id_workflow = 4';
    END IF;

    -- 1- activar o paralelismo e obter valores    
    -- 1a- activar paralelismo
    EXECUTE IMMEDIATE 'alter session enable parallel dml';

    -- 1b- obter valor original da tabela
    BEGIN
        SELECT degree
          INTO l_aux
          FROM user_tables
         WHERE table_name = 'REFERRAL_EA';
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
    EXECUTE IMMEDIATE 'ALTER TABLE REFERRAL_EA PARALLEL (DEGREE ' || l_count || ')';

    -- 4- fazer script de migracao
    UPDATE referral_ea r
       SET r.id_prof_orig =
           (SELECT roda.id_professional
              FROM ref_orig_data roda
             WHERE roda.id_external_request = r.id_external_request)
     WHERE r.id_workflow = 4
       AND r.id_prof_orig IS NULL;

    -- 5- repor valor original
    EXECUTE IMMEDIATE 'ALTER TABLE REFERRAL_EA PARALLEL (DEGREE ' || l_aux || ')';

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(g_error || ' / ' || SQLERRM);
END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 27/11/2013 11:06
-- CHANGE REASON: [ALERT-267879] 
DECLARE
    l_count PLS_INTEGER;
    l_aux   PLS_INTEGER;
BEGIN
    -- 0- fazer backup da tabela
    SELECT COUNT(1)
      INTO l_aux
      FROM user_tables t
     WHERE t.table_name = 'REFERRAL_EA_BCK2';

    IF l_aux = 0
    THEN
        pk_frmw_objects.insert_into_frmw_objects(i_owner => 'ALERT', i_obj_name => 'REFERRAL_EA_BCK2', i_obj_type => 'TABLE', i_flg_category => 'DSV');
EXECUTE IMMEDIATE 'CREATE TABLE referral_ea_bck2 AS SELECT id_external_request, id_prof_orig FROM referral_ea WHERE id_prof_orig IS NOT NULL AND (id_workflow IS NULL OR id_workflow != 4)';
    END IF;

-- 1- activar o paralelismo e obter valores    
    -- 1a- activar paralelismo
    EXECUTE IMMEDIATE 'alter session enable parallel dml';
    -- 1b- obter valor original da tabela
    BEGIN
        SELECT degree
          INTO l_aux
          FROM user_tables
         WHERE table_name = 'REFERRAL_EA';
    EXCEPTION
        WHEN no_data_found THEN
            l_aux := 1;
    END;
    -- 1c- obter o n de cpus para paralelizar
    SELECT VALUE
      INTO l_count
      FROM v$parameter
     WHERE name = 'cpu_count';

    -- 2- alterar a tabela
    EXECUTE IMMEDIATE 'ALTER TABLE REFERRAL_EA PARALLEL (DEGREE ' || l_count || ')';

    -- 3- fazer script de migracao de uma so vez
    -- id_prof_orig so deve estar preenchido quando wf=4 (para ja)
    UPDATE referral_ea r
       SET id_prof_orig = NULL
     WHERE id_prof_orig IS NOT NULL
       AND (id_workflow IS NULL OR id_workflow != 4);

    -- 4- repor valor original
    EXECUTE IMMEDIATE 'ALTER TABLE REFERRAL_EA PARALLEL (DEGREE ' || l_aux || ')';

END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 27/11/2013 11:30
-- CHANGE REASON: [ALERT-267879] 
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
         WHERE table_name = 'REFERRAL_EA';
    EXCEPTION
        WHEN no_data_found THEN
            l_aux := 1;
    END;
    -- 1c- obter o n de cpus para paralelizar
    SELECT VALUE
      INTO l_count
      FROM v$parameter
     WHERE name = 'cpu_count';
    -- 2- alterar a tabela
    EXECUTE IMMEDIATE 'ALTER TABLE REFERRAL_EA PARALLEL (DEGREE ' || l_count || ')';

    -- 3- fazer script de migracao de uma so vez
    UPDATE referral_ea r
       SET r.id_episode =
           (SELECT p.id_episode
              FROM p1_external_request p
             WHERE p.id_external_request = r.id_external_request
               AND p.id_episode IS NOT NULL)
     WHERE r.id_episode IS NULL;

    -- 4- repor valor original
    EXECUTE IMMEDIATE 'ALTER TABLE REFERRAL_EA PARALLEL (DEGREE ' || l_aux || ')';

END;
/
-- CHANGE END: Ana Monteiro