DECLARE
    l_count             PLS_INTEGER;
    l_aux               PLS_INTEGER;
    g_retval            BOOLEAN;
    g_error             VARCHAR2(1000 CHAR);
    l_id_professional   professional.id_professional%TYPE;
    o_error             t_error_out;
    l_lang              language.id_language%TYPE;
    l_prof              profissional;
    l_ref_external_inst sys_config.value%TYPE;

    TYPE t_coll_num_order IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(200 CHAR);
    l_num_order_tab t_coll_num_order;
BEGIN
    -- 0- fazer backup da tabela
    SELECT COUNT(1)
      INTO l_aux
      FROM user_tables t
     WHERE t.table_name = 'REF_ORIG_DATA_BCK';

    IF l_aux = 0
    THEN
        pk_frmw_objects.insert_into_frmw_objects(i_owner => 'ALERT', i_obj_name => 'REF_ORIG_DATA_BCK', i_obj_type => 'TABLE', i_flg_category => 'DSV');
		EXECUTE IMMEDIATE 'CREATE TABLE REF_ORIG_DATA_BCK AS SELECT * FROM REF_ORIG_DATA';
    END IF;
		
		-- 4- fazer script de migracao        
    l_ref_external_inst := to_number(pk_ref_utils.get_sys_config(i_prof          => profissional(NULL, 0, 4),
                                                                 i_id_sys_config => pk_ref_constant.g_ref_external_inst));
    l_lang              := pk_ref_constant.g_lang_pt; -- ate agora so existe em PT
    l_prof              := profissional(NULL, l_ref_external_inst, 4); -- para associar o profissional a esta instituicao (ate agora e sempre l_ref_external_inst)

    -- 4a- criar profissionais para os que nao existem na tabela professional (pelo num_order)    
    g_error := 'loop';
    FOR rec IN (SELECT DISTINCT rod.num_order, ltrim(rod.prof_name) prof_name
                  FROM ref_orig_data rod
                 WHERE rod.id_professional IS NULL
                   AND NOT EXISTS (SELECT 1
                          FROM professional p
                         WHERE p.num_order = rod.num_order))
    LOOP
        IF NOT l_num_order_tab.exists(rec.num_order)
        THEN
            -- a criar profissional para este num_order    
            l_num_order_tab(rec.num_order) := 1;
        
            g_error  := 'Call pk_ref_interface.set_professional_num_ord / i_num_order=' || rec.num_order || ' i_prof=' ||
                        pk_utils.to_string(l_prof);
            g_retval := pk_ref_interface.set_professional_num_ord(i_lang      => l_lang,
                                                                  i_prof      => l_prof,
                                                                  i_num_order => rec.num_order,
                                                                  i_prof_name => rec.prof_name,
                                                                  o_id_prof   => l_id_professional,
                                                                  o_error     => o_error);
        
            --dbms_output.put_line('NUM_ORDER='||rec.num_order||' ID_PROF='||l_id_professional);
            IF NOT g_retval
            THEN
                ROLLBACK;
                dbms_output.put_line('Error: num_order=' || rec.num_order || ' prof_name=' || rec.prof_name || ' / ' ||
                                     o_error.log_id || ' / ' || o_error.ora_sqlerrm);
            ELSE
                COMMIT;
            END IF;
        END IF;
    END LOOP;

    -- 4b- pesquisar profissionais sem roda.id_professional (rod) e com roda.num_order na tabela professional (agora ja todos deverao existir na tabela professional)
    g_error := 'DELETE FROM tbl_temp';
    DELETE FROM tbl_temp;
    INSERT INTO tbl_temp
        (num_1, vc_1)
        SELECT id_professional, num_order
          FROM (SELECT p.id_professional,
                       p.num_order,
                       row_number() over(PARTITION BY p.num_order ORDER BY p.id_professional DESC) AS rn
                  FROM ref_orig_data roda
                  JOIN professional p
                    ON (p.num_order = roda.num_order)
                 WHERE roda.id_professional IS NULL)
         WHERE rn = 1; -- existem varios profissionais com num_order repetido... vamos escolher o mais recente (com base no id_professional)

    g_error := 'UPDATE ref_orig_data roda';
    UPDATE ref_orig_data roda
       SET roda.id_professional =
           (SELECT p.num_1
              FROM tbl_temp p
             WHERE p.vc_1 = roda.num_order)
     WHERE roda.id_professional IS NULL
       AND EXISTS (SELECT 1
              FROM tbl_temp p
             WHERE p.vc_1 = roda.num_order);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(g_error || ' / ' || SQLERRM);
END;
/


-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 28/11/2013 08:48
-- CHANGE REASON: [ALERT-267879] 
DECLARE
    l_count             PLS_INTEGER;
    l_aux               PLS_INTEGER;
    g_retval            BOOLEAN;
    g_error             VARCHAR2(1000 CHAR);
    l_id_professional   professional.id_professional%TYPE;
    o_error             t_error_out;
    l_lang              language.id_language%TYPE;
    l_prof              profissional;
    l_ref_external_inst sys_config.value%TYPE;

    TYPE t_coll_num_order IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(200 CHAR);
    l_num_order_tab t_coll_num_order;
BEGIN
    -- 0- fazer backup da tabela
    SELECT COUNT(1)
      INTO l_aux
      FROM user_tables t
     WHERE t.table_name = 'REF_ORIG_DATA_BCK';

    IF l_aux = 0
    THEN
        pk_frmw_objects.insert_into_frmw_objects(i_owner        => 'ALERT',
                                                 i_obj_name     => 'REF_ORIG_DATA_BCK',
                                                 i_obj_type     => 'TABLE',
                                                 i_flg_category => 'DSV');
        EXECUTE IMMEDIATE 'CREATE TABLE REF_ORIG_DATA_BCK AS SELECT * FROM REF_ORIG_DATA';
    END IF;

    -- 4- fazer script de migracao        
    l_ref_external_inst := to_number(pk_ref_utils.get_sys_config(i_prof          => profissional(NULL, 0, 4),
                                                                 i_id_sys_config => pk_ref_constant.g_ref_external_inst));
    l_lang              := pk_ref_constant.g_lang_pt; -- ate agora so existe em PT
    l_prof              := profissional(NULL, l_ref_external_inst, 4); -- para associar o profissional a esta instituicao (ate agora e sempre l_ref_external_inst)

    -- 4a- criar profissionais para os que nao existem na tabela professional (pelo num_order)    
    g_error := 'loop';
    FOR rec IN (SELECT DISTINCT rod.num_order, ltrim(rod.prof_name) prof_name
                  FROM ref_orig_data rod
                 WHERE rod.id_professional IS NULL
                   AND rod.num_order IS NOT NULL
                   AND NOT EXISTS (SELECT 1
                          FROM professional p
                         WHERE p.num_order = rod.num_order))
    LOOP
        IF NOT l_num_order_tab.exists(rec.num_order)
        THEN
            -- a criar profissional para este num_order    
            l_num_order_tab(rec.num_order) := 1;
        
            g_error  := 'Call pk_ref_interface.set_professional_num_ord / i_num_order=' || rec.num_order || ' i_prof=' ||
                        pk_utils.to_string(l_prof);
            g_retval := pk_ref_interface.set_professional_num_ord(i_lang      => l_lang,
                                                                  i_prof      => l_prof,
                                                                  i_num_order => rec.num_order,
                                                                  i_prof_name => rec.prof_name,
                                                                  o_id_prof   => l_id_professional,
                                                                  o_error     => o_error);
        
            --dbms_output.put_line('NUM_ORDER='||rec.num_order||' ID_PROF='||l_id_professional);
            IF NOT g_retval
            THEN
                ROLLBACK;
                dbms_output.put_line('Error: num_order=' || rec.num_order || ' prof_name=' || rec.prof_name || ' / ' ||
                                     o_error.log_id || ' / ' || o_error.ora_sqlerrm);
            ELSE
                COMMIT;
            END IF;
        END IF;
    END LOOP;

    -- 4b- pesquisar profissionais sem roda.id_professional (rod) e com roda.num_order na tabela professional (agora ja todos deverao existir na tabela professional)
    g_error := 'DELETE FROM tbl_temp';
    DELETE FROM tbl_temp;
    INSERT INTO tbl_temp
        (num_1, vc_1)
        SELECT id_professional, num_order
          FROM (SELECT p.id_professional,
                       p.num_order,
                       row_number() over(PARTITION BY p.num_order ORDER BY p.id_professional DESC) AS rn
                  FROM ref_orig_data roda
                  JOIN professional p
                    ON (p.num_order = roda.num_order)
                 WHERE roda.id_professional IS NULL)
         WHERE rn = 1; -- existem varios profissionais com num_order repetido... vamos escolher o mais recente (com base no id_professional)

    g_error := 'UPDATE ref_orig_data roda';
    UPDATE ref_orig_data roda
       SET roda.id_professional =
           (SELECT p.num_1
              FROM tbl_temp p
             WHERE p.vc_1 = roda.num_order)
     WHERE roda.id_professional IS NULL
       AND EXISTS (SELECT 1
              FROM tbl_temp p
             WHERE p.vc_1 = roda.num_order);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        dbms_output.put_line(g_error || ' / ' || SQLERRM);
END;
/
-- CHANGE END: Ana Monteiro