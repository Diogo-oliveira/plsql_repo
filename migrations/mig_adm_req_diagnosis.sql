-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 20/12/2011 
-- CHANGE REASON: [ALERT-210979] DEMOS MX - OUT - Admission request- se preenche as áreas de Dx e lateralidade no pedido do procedimento cirúrgico dá erro.
DECLARE
    l_code  VARCHAR2(1000 CHAR);
    l_count PLS_INTEGER;
BEGIN

    SELECT COUNT(1)
      INTO l_count
      FROM user_tab_columns d
     WHERE d.table_name = 'ADM_REQ_DIAGNOSIS'
       AND d.column_name = 'ID_DIAGNOSIS';

    IF (l_count > 0)
    THEN
        l_code := '
DECLARE
    l_id_epis_diagnosis epis_diagnosis.id_diagnosis%TYPE;
BEGIN
    FOR rec IN (SELECT ar.id_dest_episode id_episode, ard.id_diagnosis, ard.id_adm_req_diagnosis
                  FROM adm_req_diagnosis ard
                 INNER JOIN adm_request ar
                    ON ar.id_adm_request = ard.id_adm_request
                 WHERE ard.id_diagnosis IS NOT NULL)
    LOOP
        BEGIN
            SELECT id_epis_diagnosis
              INTO l_id_epis_diagnosis
              FROM (SELECT ed.id_epis_diagnosis, decode(ed.flg_type, ''P'', 1, ''D'', 2) flg_type_order
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = rec.id_episode
                       AND ed.id_diagnosis = rec.id_diagnosis
                     ORDER BY flg_type_order)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_diagnosis := NULL;                
        END;
        IF (l_id_epis_diagnosis IS NOT NULL)
        THEN
            UPDATE adm_req_diagnosis sei
               SET sei.id_epis_diagnosis = l_id_epis_diagnosis
             WHERE sei.id_adm_req_diagnosis = rec.id_adm_req_diagnosis;
        END IF;
    END LOOP;
END';
    
        EXECUTE IMMEDIATE l_code;
    ELSE
        dbms_output.put_line('Column ID_diagnosis already dropped. Table: adm_req_diagnosis');
    END IF;

END;
/
-- CHANGED END: Sofia Mendes


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 20/12/2011 
-- CHANGE REASON: [ALERT-210979] DEMOS MX - OUT - Admission request- se preenche as áreas de Dx e lateralidade no pedido do procedimento cirúrgico dá erro.
DECLARE
    l_code  VARCHAR2(1000 CHAR);
    l_count PLS_INTEGER;
BEGIN

    SELECT COUNT(1)
      INTO l_count
      FROM user_tab_columns d
     WHERE d.table_name = 'ADM_REQ_DIAGNOSIS'
       AND d.column_name = 'ID_DIAGNOSIS';

    IF (l_count > 0)
    THEN
        l_code := '
DECLARE
    l_id_epis_diagnosis epis_diagnosis.id_diagnosis%TYPE;
BEGIN
    FOR rec IN (SELECT ar.id_dest_episode id_episode, ard.id_diagnosis, ard.id_adm_req_diagnosis
                  FROM adm_req_diagnosis ard
                 INNER JOIN adm_request ar
                    ON ar.id_adm_request = ard.id_adm_request
                 WHERE ard.id_diagnosis IS NOT NULL)
    LOOP
        BEGIN
            SELECT id_epis_diagnosis
              INTO l_id_epis_diagnosis
              FROM (SELECT ed.id_epis_diagnosis, decode(ed.flg_type, ''P'', 1, ''D'', 2) flg_type_order
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = rec.id_episode
                       AND ed.id_diagnosis = rec.id_diagnosis
                     ORDER BY flg_type_order)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_diagnosis := NULL;                
        END;
        IF (l_id_epis_diagnosis IS NOT NULL)
        THEN
            UPDATE adm_req_diagnosis sei
               SET sei.id_epis_diagnosis = l_id_epis_diagnosis
             WHERE sei.id_adm_req_diagnosis = rec.id_adm_req_diagnosis;
        END IF;
    END LOOP;
END';
    
        EXECUTE IMMEDIATE l_code;
    ELSE
        dbms_output.put_line('Column ID_diagnosis already dropped. Table: adm_req_diagnosis');
    END IF;

END;
/
-- CHANGED END: Sofia Mendes


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 20/12/2011 
-- CHANGE REASON: [ALERT-210979] DEMOS MX - OUT - Admission request- se preenche as áreas de Dx e lateralidade no pedido do procedimento cirúrgico dá erro.
DECLARE
    l_code  clob;
    l_count PLS_INTEGER;
BEGIN

    SELECT COUNT(1)
      INTO l_count
      FROM user_tab_columns d
     WHERE d.table_name = 'ADM_REQ_DIAGNOSIS'
       AND d.column_name = 'ID_DIAGNOSIS';

    IF (l_count > 0)
    THEN
        l_code := '
DECLARE
    l_id_epis_diagnosis epis_diagnosis.id_diagnosis%TYPE;
BEGIN
    FOR rec IN (SELECT ar.id_dest_episode id_episode, ard.id_diagnosis, ard.id_adm_req_diagnosis
                  FROM adm_req_diagnosis ard
                 INNER JOIN adm_request ar
                    ON ar.id_adm_request = ard.id_adm_request
                 WHERE ard.id_diagnosis IS NOT NULL)
    LOOP
        BEGIN
            SELECT id_epis_diagnosis
              INTO l_id_epis_diagnosis
              FROM (SELECT ed.id_epis_diagnosis, decode(ed.flg_type, ''P'', 1, ''D'', 2) flg_type_order
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = rec.id_episode
                       AND ed.id_diagnosis = rec.id_diagnosis
                     ORDER BY flg_type_order)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_diagnosis := NULL;                
        END;
        IF (l_id_epis_diagnosis IS NOT NULL)
        THEN
            UPDATE adm_req_diagnosis sei
               SET sei.id_epis_diagnosis = l_id_epis_diagnosis
             WHERE sei.id_adm_req_diagnosis = rec.id_adm_req_diagnosis;
        END IF;
    END LOOP;
END;
';
    
        EXECUTE IMMEDIATE l_code;
    ELSE
        dbms_output.put_line('Column ID_diagnosis already dropped. Table: adm_req_diagnosis');
    END IF;

END;
/
-- CHANGED END: Sofia Mendes
